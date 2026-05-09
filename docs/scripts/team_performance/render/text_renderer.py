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
        f"repo={cfg.get('repo')!r} sprint_start={cfg.get('sprint_start')} "
        f"sprint_length_days={cfg.get('sprint_length_days')} as_of={cfg.get('as_of')} "
        f"scope_growth={cfg.get('scope_growth')}"
    )

    # ── Sprints ──────────────────────────────────────────────────────────
    sprints_table = Table(title="Sprints completados", title_style="bold")
    sprints_table.add_column("#", justify="right")
    sprints_table.add_column("Ventana")
    sprints_table.add_column("Cerrados", justify="right")
    sprints_table.add_column("Excl.", justify="right")
    sprints_table.add_column("Creados", justify="right")
    sprints_table.add_column("WIP@fin", justify="right")
    for sprint in report.sprints:
        window = f"{sprint.start.date().isoformat()} → {sprint.end.date().isoformat()}"
        sprints_table.add_row(
            str(sprint.index),
            window,
            str(len(sprint.closed)),
            str(len(sprint.closed_excluded)),
            str(len(sprint.created)),
            str(sprint.wip_at_end),
        )
    sprints_table.caption = (
        "Cerrados = entregados (state_reason=COMPLETED). "
        "Excl. = cerrados-pero-no-entregados (not_planned, duplicate). "
        "Creados = ítems agregados al alcance. WIP@fin = ítems abiertos al cierre del sprint."
    )
    console.print(sprints_table)

    # ── Aggregate ────────────────────────────────────────────────────────
    agg = report.aggregate
    if agg.throughput is not None:
        t = agg.throughput
        rows: list[tuple[str, str, str]] = [
            ("Media", _fmt_float(t.mean), "Promedio de issues *entregados* por sprint."),
            ("Mediana", _fmt_float(t.median), "Issues entregados por sprint en un sprint típico."),
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
            (
                "Cierres excluidos",
                str(agg.closed_excluded_total),
                "Cerrados como not_planned/duplicate, *no* contados como trabajo entregado.",
            ),
        ]
        console.print(_stat_table("Throughput (issues entregados / sprint)", rows))
    else:
        console.print("[muted]No hay sprints completados en la ventana.[/]")

    if agg.cycle_time_days is not None:
        c = agg.cycle_time_days
        console.print(
            _stat_table(
                "Tiempo de ciclo (días desde creación → cierre, sólo entregados)",
                [
                    (
                        "p50",
                        _fmt_float(c.p50, digits=1),
                        "La mitad de los issues se completan dentro de estos días.",
                    ),
                    (
                        "p75",
                        _fmt_float(c.p75, digits=1),
                        "Tres cuartos se completan dentro de estos días.",
                    ),
                    (
                        "p90",
                        _fmt_float(c.p90, digits=1),
                        "Nueve de cada diez se completan dentro de estos días.",
                    ),
                ],
            )
        )

    # ── Projection ───────────────────────────────────────────────────────
    if report.projection is None:
        if cfg.get("target_issues") is not None:
            console.print(
                "[yellow]Proyección retenida:[/] se requieren ≥ 2 sprints completados. "
                "Las métricas observadas más arriba siguen siendo válidas."
            )
        return

    p = report.projection
    inv = p.sprints_to_target
    console.print(
        _stat_table(
            f"Sprints para cerrar ≥ {p.target_issues} issues "
            f"(bootstrap {'split' if p.scope_growth_enabled else 'plano'}, "
            f"{p.bootstrap_samples} muestras)",
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
                        "P(cerrar ≥ target)",
                        _fmt_pct(f.p_meet_or_exceed_target),
                        "Probabilidad de terminar el backlog dentro del horizonte fijo.",
                    ),
                    (
                        "Total proyectado p10",
                        str(f.total_projected_p10),
                        "Total cerrado pesimista — sólo el 10% de los futuros es peor.",
                    ),
                    (
                        "Total proyectado p50",
                        str(f.total_projected_p50),
                        "Total cerrado mediano sobre el horizonte.",
                    ),
                    (
                        "Total proyectado p90",
                        str(f.total_projected_p90),
                        "Total cerrado optimista — sólo el 10% de los futuros lo supera.",
                    ),
                ],
            )
        )

    if p.scope_growth is not None:
        s = p.scope_growth
        console.print(
            _stat_table(
                "Crecimiento de alcance — ítems *agregados* por sprint (infla el target)",
                [
                    (
                        "Media",
                        _fmt_float(s.created_per_sprint_mean),
                        "Promedio de ítems agregados por sprint.",
                    ),
                    (
                        "Mediana",
                        str(s.created_per_sprint_median),
                        "Ítems agregados por sprint en un sprint típico.",
                    ),
                    (
                        "Mín",
                        str(s.created_per_sprint_min),
                        "Sprint histórico más tranquilo en intake.",
                    ),
                    (
                        "Máx",
                        str(s.created_per_sprint_max),
                        "Sprint histórico más ruidoso en intake.",
                    ),
                ],
            )
        )
