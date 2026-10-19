"""Balanceamento por simulação: joga a campanha com jogadores simulados.

Uso:
    python tools/sim/simulate.py                  # todos os perfis de versão (mvp, full)
    python tools/sim/simulate.py --release full   # só um perfil de release.json
    python tools/sim/simulate.py --seeds 50       # mais sementes
    python tools/sim/simulate.py --release full --report r.json  # relatório já gerado (sem Godot)

Roda game/sim/run_campaign.gd na Godot em modo headless, lê o relatório JSON
e calcula, por perfil de jogador:
  - taxa de cumprir a meta do dia 1 na primeira tentativa;
  - taxa de terminar a campanha;
  - média de tentativas por dia (sem contar as repetições para juntar moedas);
  - repetições para juntar moedas, quando o próximo dia espera uma melhoria (P-26);
  - intervalo médio, em dias jogados, entre "grandes melhorias" (compras
    com custo >= big_purchase_min_cost). O GDD pede uma a cada 2 ou 3 dias;
  - peixes e pontuação média por dia (base da pontuação-alvo, P-19).
Sai com código 1 se alguma métrica ficar fora das metas de sim_profiles.json.
O relatório completo fica em reports/sim/.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "tools" / "godot"))

import fetch_godot  # noqa: E402

PROFILES_FILE = REPO_ROOT / "game" / "content" / "sim_profiles.json"
REPORT_DIR = REPO_ROOT / "reports" / "sim"


def load_balance() -> dict:
    """Metas por perfil de versão: {"mvp": {...}, "full": {...}}."""
    return json.loads(PROFILES_FILE.read_text(encoding="utf-8"))["balance"]


def run_godot(release: str, bots: list[str], seeds: int, out: Path) -> None:
    toolchain = fetch_godot.load_toolchain()
    godot = str(fetch_godot.fetch_godot(toolchain))
    game = REPO_ROOT / "game"
    subprocess.run([godot, "--headless", "--path", str(game), "--import"], check=True,
                   capture_output=True)
    out.parent.mkdir(parents=True, exist_ok=True)
    cmd = [godot, "--headless", "--path", str(game), "-s", "res://sim/run_campaign.gd", "--",
           "--release", release, "--bots", ",".join(bots), "--seeds", str(seeds), "--out", str(out)]
    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode != 0 or not out.is_file():
        tail = "\n".join((result.stdout + result.stderr).splitlines()[-20:])
        raise SystemExit(f"ERRO: simulação falhou (código {result.returncode}):\n{tail}")


def big_purchase_intervals(run: dict, min_cost: int) -> list[float]:
    """Dias jogados entre grandes compras (o primeiro conta a partir do início)."""
    sessions = sorted({p["session"] for p in run["purchases"] if p["cost"] >= min_cost})
    previous = 0
    intervals = []
    for session in sessions:
        intervals.append(float(session - previous))
        previous = session
    return intervals


def _mean_by_day(values: dict[int, list[float]]) -> dict[int, float]:
    return {day: round(sum(v) / len(v), 2) for day, v in sorted(values.items())}


def metrics_for(runs: list[dict], min_cost: int) -> dict:
    total = len(runs)
    first_sessions = [r["sessions"][0] for r in runs if r["sessions"]]
    days_cleared = 0
    attempts = 0
    farm_sessions = 0
    intervals: list[float] = []
    best_stars: list[int] = []
    fish_by_day: dict[int, list[float]] = {}
    score_by_day: dict[int, list[float]] = {}
    for run in runs:
        best: dict[int, int] = {}
        for s in run["sessions"]:
            if s.get("farm", False):
                farm_sessions += 1
                continue
            attempts += 1
            best[s["day"]] = max(best.get(s["day"], 0), s["stars"])
            fish_by_day.setdefault(s["day"], []).append(s["fish"])
            score_by_day.setdefault(s["day"], []).append(s.get("score", 0))
        days_cleared += sum(1 for stars in best.values() if stars > 0)
        best_stars += [stars for stars in best.values() if stars > 0]
        intervals += big_purchase_intervals(run, min_cost)
    return {
        "runs": total,
        "day1_goal_rate": sum(1 for s in first_sessions if s["goal_met"]) / max(len(first_sessions), 1),
        "completion_rate": sum(1 for r in runs if r["completed"]) / max(total, 1),
        "mean_attempts_per_day": attempts / max(days_cleared, 1),
        "farm_sessions_per_run": farm_sessions / max(total, 1),
        "mean_stars": sum(best_stars) / max(len(best_stars), 1),
        "big_purchase_interval_days": sum(intervals) / len(intervals) if intervals else float("inf"),
        "big_purchases_per_run": len(intervals) / max(total, 1),
        "mean_fish_by_day": _mean_by_day(fish_by_day),
        "mean_score_by_day": _mean_by_day(score_by_day),
        "mean_final_coins": sum(r["final_coins"] for r in runs) / max(total, 1),
    }


def check(metrics: dict, target: dict) -> list[str]:
    failures = []
    if metrics["day1_goal_rate"] < target["day1_goal_rate_min"]:
        failures.append(f"meta do dia 1 na 1ª tentativa {metrics['day1_goal_rate']:.0%} < {target['day1_goal_rate_min']:.0%}")
    if metrics["completion_rate"] < target["completion_rate_min"]:
        failures.append(f"campanhas completas {metrics['completion_rate']:.0%} < {target['completion_rate_min']:.0%}")
    if metrics["mean_attempts_per_day"] > target["mean_attempts_per_day_max"]:
        failures.append(f"tentativas por dia {metrics['mean_attempts_per_day']:.2f} > {target['mean_attempts_per_day_max']}")
    low, high = target["big_purchase_interval_days"]
    interval = metrics["big_purchase_interval_days"]
    if not low <= interval <= high:
        failures.append(f"intervalo entre grandes melhorias {interval:.2f} dias fora de [{low}, {high}]")
    if "mean_stars_min" in target and metrics["mean_stars"] < target["mean_stars_min"]:
        failures.append(f"média de estrelas {metrics['mean_stars']:.2f} < {target['mean_stars_min']}")
    if "farm_sessions_per_run_max" in target and metrics["farm_sessions_per_run"] > target["farm_sessions_per_run_max"]:
        failures.append(f"repetições para juntar moedas {metrics['farm_sessions_per_run']:.2f} > "
                        f"{target['farm_sessions_per_run_max']}")
    return failures


def evaluate(release: str, balance: dict, report: dict) -> tuple[dict, bool]:
    """Métricas e falhas de cada perfil de jogador num perfil de versão."""
    summary = {}
    failed = False
    for bot, target in balance["targets"].items():
        runs = [r for r in report["runs"] if r["bot"] == bot]
        metrics = metrics_for(runs, balance["big_purchase_min_cost"])
        failures = check(metrics, target)
        summary[bot] = {"metrics": metrics, "failures": failures}
        failed |= bool(failures)
        print(f"== {release} / {bot} ({metrics['runs']} campanhas)")
        print(f"   meta do dia 1 (1ª tentativa): {metrics['day1_goal_rate']:.0%}")
        print(f"   campanhas completas: {metrics['completion_rate']:.0%}")
        print(f"   tentativas por dia: {metrics['mean_attempts_per_day']:.2f}")
        print(f"   repetições para juntar moedas: {metrics['farm_sessions_per_run']:.2f} por campanha")
        print(f"   média de estrelas: {metrics['mean_stars']:.2f}")
        print(f"   grandes melhorias por campanha: {metrics['big_purchases_per_run']:.1f}, "
              f"a cada {metrics['big_purchase_interval_days']:.2f} dias")
        print(f"   peixes por dia (média): {metrics['mean_fish_by_day']}")
        print(f"   pontos por dia (média): {metrics['mean_score_by_day']}")
        print(f"   moedas no fim: {metrics['mean_final_coins']:.0f}")
        for failure in failures:
            print(f"   FORA DA META: {failure}")
    return summary, failed


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--release", help="perfil de release.json (padrão: todos)")
    parser.add_argument("--seeds", type=int)
    parser.add_argument("--report", type=Path, help="relatório já gerado (pula a Godot; exige --release)")
    args = parser.parse_args(argv)
    sys.stdout.reconfigure(encoding="utf-8")

    all_balance = load_balance()
    releases = [args.release] if args.release else list(all_balance)
    if args.report is not None and len(releases) != 1:
        parser.error("--report precisa de --release")
    summary = {}
    failed = False
    for release in releases:
        balance = all_balance[release]
        report_path = args.report or REPORT_DIR / f"campaign_report_{release}.json"
        if args.report is None:
            run_godot(release, list(balance["targets"]), args.seeds or balance["seeds"], report_path)
        report = json.loads(report_path.read_text(encoding="utf-8"))
        summary[release], release_failed = evaluate(release, balance, report)
        failed |= release_failed
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    (REPORT_DIR / "summary.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8")
    print("FALHOU — balanceamento fora das metas." if failed else "OK — balanceamento dentro das metas.")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
