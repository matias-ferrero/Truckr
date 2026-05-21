"""Render a Report to rich tables on a Console (typically stderr).

Every metric prints with a one-line caption so a reader can interpret it
without consulting the README. User-facing copy is in es-AR per project
convention; identifiers stay English.
"""

from __future__ import annotations

from rich.console import Console
from rich.table import Table

from team_performance.models import Report


def _fmt_float(value: float | None, digits: int = 2) -> str:
    return "—" if value is None else f"{value:.{digits}f}"


def _fmt_int(value: int | None) -> str:
    return "—" if value is None else str(value)


def _fmt_pct(value: float) -> str:
    return f"{value * 100:.1f}%"


def _stat_table(
    title: str, rows: list[tuple[str, str, str]], description: str | None = None
) -> Table:
    """rows = [(metric_name, value, meaning)]."""
    table = Table(title=title, title_style="bold", show_header=True)
    table.add_column("Métrica", no_wrap=True)
    table.add_column("Valor", justify="right", no_wrap=True)
    table.add_column("Significado")
    for name, value, meaning in rows:
        table.add_row(name, value, meaning)
    if description:
        table.caption = description
    return table


def render_text(report: Report, console: Console) -> None:
    console.print(f"[bold]Performance del equipo[/] — esquema {report.schema_version}")
    cfg = report.config_snapshot
    console.print(
        f"sprints_dir={cfg.get('sprints_dir')!r} phase={cfg.get('phase')} "
        f"target_user_stories={cfg.get('target_user_stories')}"
    )

    # ── Sprints ──────────────────────────────────────────────────────────
    sprints_table = Table(title="Sprints completados", title_style="bold")
    sprints_table.add_column("#", justify="right")
    sprints_table.add_column("Ventana")
    sprints_table.add_column("US completadas", justify="right")
    sprints_table.add_column("WIP@fin", justify="right")
    for sprint in report.sprints:
        window = f"{sprint.window_start.isoformat()} → {sprint.window_end.isoformat()}"
        sprints_table.add_row(
            str(sprint.index),
            window,
            str(len(sprint.completed)),
            str(len(sprint.in_progress)),
        )
    sprints_table.caption = (
        "US completadas = User Stories terminadas en el sprint. "
        "WIP@fin = User Stories en progreso (no terminadas) al cierre del sprint."
    )
    console.print(sprints_table)

    # ── Aggregate ────────────────────────────────────────────────────────
    agg = report.aggregate
    if agg.throughput is not None:
        t = agg.throughput
        rows: list[tuple[str, str, str]] = [
            ("Media", _fmt_float(t.mean), "Promedio de User Stories completadas por sprint."),
            ("Mediana", _fmt_float(t.median), "User Stories completadas en un sprint típico."),
            (
                "Desv. estándar",
                _fmt_float(t.stdev),
                "Dispersión alrededor de la media — mayor = cadencia menos predecible.",
            ),
            ("Mín", str(t.min), "Peor sprint observado."),
            ("Máx", str(t.max), "Mejor sprint observado."),
            (
                "Tamaño de muestra (sprints)",
                str(agg.sample_size_sprints),
                "Sprints completados que alimentan el bootstrap. Menos de 8 = pronóstico ancho.",
            ),
        ]
        console.print(_stat_table("Throughput (User Stories completadas / sprint)", rows))
    else:
        console.print("[muted]No hay sprints completados en el ledger.[/]")

    if agg.lead_time_sprints is not None:
        c = agg.lead_time_sprints
        console.print(
            _stat_table(
                "Lead time (sprints desde primer trabajo → completado)",
                [
                    (
                        "p50",
                        _fmt_float(c.p50, digits=1),
                        "La mitad de las US se completan dentro de esta cantidad de sprints.",
                    ),
                    (
                        "p75",
                        _fmt_float(c.p75, digits=1),
                        "Tres cuartos se completan dentro de esta cantidad de sprints.",
                    ),
                    (
                        "p90",
                        _fmt_float(c.p90, digits=1),
                        "Nueve de cada diez se completan dentro de esta cantidad de sprints.",
                    ),
                ],
            )
        )

    # ── Projection ───────────────────────────────────────────────────────
    if report.projection is None:
        if cfg.get("target_user_stories") is not None:
            console.print(
                "[yellow]Proyección retenida:[/] se requieren ≥ 2 sprints completados. "
                "Las métricas observadas más arriba siguen siendo válidas."
            )
        return

    p = report.projection
    inv = p.sprints_to_target
    console.print(
        _stat_table(
            f"Sprints para completar ≥ {p.target_user_stories} User Stories "
            f"(bootstrap, {p.bootstrap_samples} muestras)",
            [
                (
                    "p50",
                    _fmt_int(inv.p50),
                    "La mitad de los futuros simulados terminan en este sprint (mediana).",
                ),
                (
                    "p85",
                    _fmt_int(inv.p85),
                    "Línea base de planificación — el 85% de los futuros terminan en este sprint.",
                ),
                (
                    "p95",
                    _fmt_int(inv.p95),
                    "Compromiso con confianza — el 95% de los futuros terminan en este sprint.",
                ),
                (
                    "p99",
                    _fmt_int(inv.p99),
                    "Peor caso — el 99% de los futuros terminan en este sprint.",
                ),
                (
                    "did_not_finish",
                    _fmt_pct(inv.did_not_finish_pct),
                    (
                        f"% de simulaciones que llegan al tope de {inv.cap_sprints} sprints "
                        "sin terminar. Distinto de cero ⇒ alcance > capacidad."
                    ),
                ),
            ],
        )
    )

    if p.forward is not None:
        f = p.forward
        console.print(
            _stat_table(
                f"Horizonte fijo — {f.remaining_sprints} sprints restantes",
                [
                    (
                        "P(completar ≥ target)",
                        _fmt_pct(f.p_meet_or_exceed_target),
                        "Probabilidad de terminar el backlog dentro del horizonte fijo.",
                    ),
                    (
                        "Total proyectado p10",
                        str(f.total_projected_p10),
                        "Total de US completadas pesimista — sólo el 10% de los futuros es peor.",
                    ),
                    (
                        "Total proyectado p50",
                        str(f.total_projected_p50),
                        "Total mediano de US completadas sobre el horizonte.",
                    ),
                    (
                        "Total proyectado p90",
                        str(f.total_projected_p90),
                        "Total de US completadas optimista — sólo el 10% de los futuros lo supera.",
                    ),
                ],
            )
        )
