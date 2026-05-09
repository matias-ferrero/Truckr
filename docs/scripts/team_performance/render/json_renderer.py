"""Render a Report to a stable, byte-identical JSON string.

``schema_version`` permits future evolution. ``include_generated_at=False``
omits the wall-clock so tests can compare byte-for-byte.

Schema v2 emits inverse + (optional) forward projection blocks alongside
``aggregate.created_per_sprint`` and ``aggregate.closed_excluded_total``.
Each metric is paired with a one-line ``_meaning`` companion field so any
downstream consumer renders metric + explanation together — no orphaned
numbers.
"""

from __future__ import annotations

import json
from dataclasses import asdict, is_dataclass
from datetime import date, datetime
from typing import Any

from team_performance.models import Projection, Report


def _default(obj: object) -> Any:
    if isinstance(obj, datetime | date):
        return obj.isoformat()
    if is_dataclass(obj) and not isinstance(obj, type):
        return asdict(obj)
    if isinstance(obj, tuple):
        return list(obj)
    raise TypeError(f"cannot serialize {type(obj).__name__}")


def _projection_block(p: Projection) -> dict[str, Any]:
    out: dict[str, Any] = {
        "target_issues": p.target_issues,
        "target_issues_meaning": "Cantidad inicial de issues del backlog provista por el operador.",
        "method": p.method,
        "method_meaning": (
            "split_bootstrap_throughput también modela el crecimiento del backlog; "
            "bootstrap_throughput muestrea sólo lo entregado."
        ),
        "scope_growth_enabled": p.scope_growth_enabled,
        "scope_growth_enabled_meaning": (
            "Cuando es verdadero, cada sprint simulado también suma una cantidad "
            "muestreada de ítems creados al target acumulado."
        ),
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
                "Probabilidad de cerrar ≥ target issues dentro del horizonte fijo."
            ),
            "total_projected_p10": f.total_projected_p10,
            "total_projected_p10_meaning": (
                "Total cerrado proyectado pesimista — sólo el 10% de los futuros es peor."
            ),
            "total_projected_p50": f.total_projected_p50,
            "total_projected_p50_meaning": ("Total cerrado proyectado mediano sobre el horizonte."),
            "total_projected_p90": f.total_projected_p90,
            "total_projected_p90_meaning": (
                "Total cerrado proyectado optimista — sólo el 10% de los futuros lo supera."
            ),
        }
    out["scope_growth"] = None
    if p.scope_growth is not None:
        s = p.scope_growth
        out["scope_growth"] = {
            "created_per_sprint_mean": s.created_per_sprint_mean,
            "created_per_sprint_mean_meaning": (
                "Promedio histórico de ítems agregados al alcance por sprint — usado para "
                "hacer crecer el target."
            ),
            "created_per_sprint_median": s.created_per_sprint_median,
            "created_per_sprint_median_meaning": (
                "Ítems agregados por sprint en un sprint típico."
            ),
            "created_per_sprint_min": s.created_per_sprint_min,
            "created_per_sprint_min_meaning": "Sprint más tranquilo por intake.",
            "created_per_sprint_max": s.created_per_sprint_max,
            "created_per_sprint_max_meaning": "Sprint más ruidoso por intake.",
        }
    return out


def render_json(report: Report, *, include_generated_at: bool = True) -> str:
    payload: dict[str, Any] = {
        "schema_version": report.schema_version,
        "config_snapshot": report.config_snapshot,
        "sprints": [
            {
                "index": s.index,
                "start": s.start.isoformat(),
                "end": s.end.isoformat(),
                "closed_count": len(s.closed),
                "closed_excluded_count": len(s.closed_excluded),
                "created_count": len(s.created),
                "wip_at_end": s.wip_at_end,
                "closed_numbers": [i.number for i in s.closed],
                "closed_excluded_numbers": [i.number for i in s.closed_excluded],
            }
            for s in report.sprints
        ],
        "aggregate": asdict(report.aggregate),
        "projection": _projection_block(report.projection)
        if report.projection is not None
        else None,
    }
    if include_generated_at:
        payload["generated_at"] = report.generated_at.isoformat()
    return json.dumps(payload, indent=2, sort_keys=True, default=_default)
