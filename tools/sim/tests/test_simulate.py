"""Testes das métricas do simulador (rodar: python -m unittest discover -s tools/sim/tests -v)."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import simulate  # noqa: E402


def session(day, stars, fish=8, attempt=1):
    return {"day": day, "stars": stars, "goal_met": stars > 0, "fish": fish, "attempt": attempt}


def run(sessions, purchases, completed=True, coins=100):
    return {"sessions": sessions, "purchases": purchases, "completed": completed, "final_coins": coins}


class MetricsTest(unittest.TestCase):
    def test_big_purchase_intervals_ignore_cheap_items(self):
        r = run([], [{"session": 3, "cost": 700}, {"session": 4, "cost": 50}, {"session": 7, "cost": 900}])
        self.assertEqual(simulate.big_purchase_intervals(r, 700), [3.0, 4.0])

    def test_purchases_in_same_session_count_once(self):
        r = run([], [{"session": 2, "cost": 800}, {"session": 2, "cost": 900}])
        self.assertEqual(simulate.big_purchase_intervals(r, 700), [2.0])

    def test_metrics(self):
        runs = [
            run([session(1, 2), session(2, 0), session(2, 3)], [{"session": 2, "cost": 700}]),
            run([session(1, 0), session(1, 1)], [], completed=False),
        ]
        m = simulate.metrics_for(runs, 700)
        self.assertEqual(m["day1_goal_rate"], 0.5)
        self.assertEqual(m["completion_rate"], 0.5)
        self.assertAlmostEqual(m["mean_attempts_per_day"], 5 / 3)
        self.assertAlmostEqual(m["mean_stars"], 2.0)
        self.assertEqual(m["big_purchase_interval_days"], 2.0)

    def test_farm_sessions_are_counted_apart(self):
        farm = dict(session(1, 2, fish=9), farm=True)
        runs = [run([session(1, 1), farm, session(2, 2)], [])]
        m = simulate.metrics_for(runs, 700)
        self.assertEqual(m["farm_sessions_per_run"], 1.0)
        self.assertAlmostEqual(m["mean_attempts_per_day"], 1.0)
        self.assertEqual(m["mean_fish_by_day"], {1: 8.0, 2: 8.0})

    def test_check_flags_too_much_farming(self):
        metrics = {"day1_goal_rate": 0.9, "completion_rate": 1.0, "mean_attempts_per_day": 1.1,
                   "big_purchase_interval_days": 2.5, "mean_stars": 2.5, "farm_sessions_per_run": 9.0}
        target = {"day1_goal_rate_min": 0.6, "completion_rate_min": 0.9, "mean_attempts_per_day_max": 1.6,
                  "big_purchase_interval_days": [2.0, 3.0], "farm_sessions_per_run_max": 7.0}
        self.assertEqual(len(simulate.check(metrics, target)), 1)

    def test_check_flags_each_target(self):
        metrics = {"day1_goal_rate": 0.5, "completion_rate": 0.8, "mean_attempts_per_day": 2.0,
                   "big_purchase_interval_days": 5.0, "mean_stars": 1.0}
        target = {"day1_goal_rate_min": 0.6, "completion_rate_min": 0.9, "mean_attempts_per_day_max": 1.6,
                  "big_purchase_interval_days": [2.0, 3.0], "mean_stars_min": 2.0}
        self.assertEqual(len(simulate.check(metrics, target)), 5)

    def test_check_passes_inside_targets(self):
        metrics = {"day1_goal_rate": 0.9, "completion_rate": 1.0, "mean_attempts_per_day": 1.1,
                   "big_purchase_interval_days": 2.5, "mean_stars": 2.5}
        target = {"day1_goal_rate_min": 0.6, "completion_rate_min": 0.9, "mean_attempts_per_day_max": 1.6,
                  "big_purchase_interval_days": [2.0, 3.0]}
        self.assertEqual(simulate.check(metrics, target), [])


if __name__ == "__main__":
    unittest.main()
