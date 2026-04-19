import type { PropsWithChildren } from "react";

export function Panel({
  children,
  className = ""
}: PropsWithChildren<{ className?: string }>) {
  const classes = ["panel", className].filter(Boolean).join(" ");
  return (
    <section className={classes}>
      <div className="panel-inner">{children}</div>
    </section>
  );
}

export function SectionTitle({
  kicker,
  title,
  detail
}: {
  kicker: string;
  title: string;
  detail: string;
}) {
  return (
    <header>
      <p className="panel-kicker">{kicker}</p>
      <h2 className="panel-title">{title}</h2>
      <p className="panel-detail">{detail}</p>
    </header>
  );
}

export function StatusBadge({ label }: { label: string }) {
  return <span className="status-badge">{label}</span>;
}

