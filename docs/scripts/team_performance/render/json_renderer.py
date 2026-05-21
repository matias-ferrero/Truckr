"""Render a Report to a stable, byte-identical JSON string.

``schema_version`` permits future evolution. ``include_generated_at=False``
omits the wall-clock so tests can compare byte-for-byte.

Schema v3 emits User-Story throughput, lead time measured in sprints, and the
inverse + (optional) forward projection. Each metric is paired with a one-line
``_meaning`` companion field (es-AR) so any downstream consumer renders metric
+ explanation together — no orphaned numbers.
"""

from __future__ import annotations

import json
from dataclasses import asdict, is_dataclass
from datetime import date, datetime
from typing import Any

from team_performance.models import AggregateStats, Projection, Report


def _default(obj: object) -> Any:
    if isinstance(obj, datetime | date):
        return obj.isoformat()
    if is_dataclass(obj) and not isinstance(obj, type):
        return asdict(obj)
    if isinstance(obj, tuple):
        return list(obj)
    raise TypeError(f"cannot serialize {type(obj).__name__}")


def _aggregate_block(agg: AggregateStats) -> dict[str, Any]:
    out: dict[str, Any] = {"sample_size_sprints": agg.sample_size_sprints}
    if agg.throughput is None:
        out["throughput"] = None
    else:
        t = agg.throughput
        out["throughput"] = {
            "mean": t.mean,
            "mean_meaning": "Promedio de User Stories completadas por sprint.",
            "median": t.median,
            "median_meaning": "User Stories completadas en un sprint típico.",
            "stdev": t.stdev,
            "stdev_meaning": "Dispersión alrededor de la media — mayor = menos predecible.",
            "min": t.min,
            "min_meaning": "Peor sprint observado.",
            "max": t.max,
            "max_meaning": "Mejor sprint observado.",
        }
    if agg.lead_time_sprints is None:
        out["lead_time_sprints"] = None
    else:
        c = agg.lead_time_sprints
        out["lead_time_sprints"] = {
            "p50": c.p50,
            "p50_meaning": "La mitad de las US se completan dentro de esta cantidad de sprints.",
            "p75": c.p75,
            "p75_meaning": (
                "Tres cuartos de las US se completan dentro de esta cantidad de sprints."
            ),
            "p90": c.p90,
            "p90_meaning": "Nueve de cada diez US se completan dentro de esta cantidad de sprints.",
        }
    return out


def _projection_block(p: Projection) -> dict[str, Any]:
    out: dict[str, Any] = {
        "target_user_stories": p.target_user_stories,
        "target_user_stories_meaning": (
            "Cantidad de User Stories del backlog a alcanzar, provista por el operador."
        ),
        "method": p.method,
        "method_meaning": "bootstrap_throughput muestrea el throughput observado por sprint.",
        "bootstrap_samples": p.bootstrap_samples,
        "bootstrap_samples_meaning": "Cantidad de futuros simulados independientes.",
        "sprints_to_target": {
            "p50": p.sprints_to_target.p50,
            "p50_meaning": "El 50% de las simulaciones terminan en este sprint (mediana).",
            "p85": p.sprints_to_target.p85,
            "p85_meaning": (
                "El 85% de las simulaciones terminan en este sprint (línea base de planificación)."
            ),
            "p95": p.sprints_to_target.p95,
            "p95_meaning": (
                "El 95% de las simulaciones terminan en este sprint (compromiso con confianza)."
            ),
            "p99": p.sprints_to_target.p99,
            "p99_meaning": (
                "El 99% de las simulaciones terminan en este sprint (techo del peor caso)."
            ),
            "did_not_finish_pct": p.sprints_to_target.did_not_finish_pct,
            "did_not_finish_pct_meaning": (
                "Fracción de simulaciones que llegan al tope de sprints por ensayo sin "
                "alcanzar el target — distinto de cero ⇒ alcance > capacidad en el rango modelado."
            ),
            "cap_sprints": p.sprints_to_target.cap_sprints,
            "cap_sprints_meaning": "Cantidad máxima de sprints simulados por ensayo.",
        },
    }
    out["forward"] = None
    if p.forward is not None:
        f = p.forward
        out["forward"] = {
            "remaining_sprints": f.remaining_sprints,
            "remaining_sprints_meaning": "Horizonte fijo sobre el que se consulta.",
            "p_meet_or_exceed_target": f.p_meet_or_exceed_target,
            "p_meet_or_exceed_target_meaning": (
                "Probabilidad de completar ≥ target User Stories dentro del horizonte fijo."
            ),
            "total_projected_p10": f.total_projected_p10,
            "total_projected_p10_meaning": (
                "Total proyectado de US completadas pesimista — sólo el 10% de los futuros es peor."
            ),
            "total_projected_p50": f.total_projected_p50,
            "total_projected_p50_meaning": "Total mediano de US completadas sobre el horizonte.",
            "total_projected_p90": f.total_projected_p90,
            "total_projected_p90_meaning": (
                "Total proyectado de US completadas optimista — sólo el 10% de los futuros lo "
                "supera."
            ),
        }
    return out


def render_json(report: Report, *, include_generated_at: bool = True) -> str:
    payload: dict[str, Any] = {
        "schema_version": report.schema_version,
        "config_snapshot": report.config_snapshot,
        "sprints": [
            {
                "index": s.index,
                "phase": s.phase,
                "window_start": s.window_start.isoformat(),
                "window_end": s.window_end.isoformat(),
                "completed_count": len(s.completed),
                "completed_user_stories": list(s.completed),
                "wip_at_end": len(s.in_progress),
                "in_progress_user_stories": list(s.in_progress),
            }
            for s in report.sprints
        ],
        "aggregate": _aggregate_block(report.aggregate),
        "projection": _projection_block(report.projection)
        if report.projection is not None
        else None,
    }
    if include_generated_at:
        payload["generated_at"] = report.generated_at.isoformat()
    return json.dumps(payload, indent=2, sort_keys=True, default=_default)
