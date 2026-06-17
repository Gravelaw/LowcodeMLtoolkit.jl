import type { ReactNode } from "react";

export function Card({
  children,
  className = "",
  title,
  eyebrow,
  action
}: {
  children: ReactNode;
  className?: string;
  title?: string;
  eyebrow?: string;
  action?: ReactNode;
}) {
  return (
    <section className={`jf-card ${className}`.trim()}>
      {(title || eyebrow || action) && (
        <div className="jf-card-head">
          <div>
            {eyebrow ? <p className="jf-eyebrow">{eyebrow}</p> : null}
            {title ? <h2>{title}</h2> : null}
          </div>
          {action ? <div className="jf-card-action">{action}</div> : null}
        </div>
      )}
      {children}
    </section>
  );
}

export function MetricCard({
  label,
  value,
  detail,
  tone = "purple"
}: {
  label: string;
  value: string;
  detail: string;
  tone?: "purple" | "green" | "blue" | "orange";
}) {
  return (
    <div className={`metric-card tone-${tone}`}>
      <span>{label}</span>
      <strong>{value}</strong>
      <small>{detail}</small>
      <div className="sparkline" aria-hidden="true">
        <i />
        <i />
        <i />
        <i />
        <i />
        <i />
      </div>
    </div>
  );
}

export function StatusPill({
  children,
  tone = "green"
}: {
  children: ReactNode;
  tone?: "green" | "purple" | "blue" | "orange" | "neutral";
}) {
  return <span className={`status-pill tone-${tone}`}>{children}</span>;
}

export function DataTable<TItem extends object>({
  columns,
  rows,
  getRowKey
}: {
  columns: Array<{ key: keyof TItem | string; label: string; render?: (row: TItem) => ReactNode }>;
  rows: TItem[];
  getRowKey: (row: TItem, index: number) => string;
}) {
  return (
    <div className="table-wrap">
      <table>
        <thead>
          <tr>
            {columns.map((column) => (
              <th key={String(column.key)}>{column.label}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row, index) => (
            <tr key={getRowKey(row, index)}>
              {columns.map((column) => (
                <td key={String(column.key)}>
                  {column.render
                    ? column.render(row)
                    : String((row as Record<string, unknown>)[String(column.key)] ?? "")}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function CodeBlock({ children, label }: { children: string; label: string }) {
  return (
    <div className="code-block">
      <div>{label}</div>
      <pre>{children}</pre>
    </div>
  );
}

export function Button({
  children,
  onClick,
  variant = "secondary",
  ariaLabel
}: {
  children: ReactNode;
  onClick?: () => void;
  variant?: "primary" | "secondary" | "ghost";
  ariaLabel?: string;
}) {
  return (
    <button className={`jf-button ${variant}`} onClick={onClick} type="button" aria-label={ariaLabel}>
      {children}
    </button>
  );
}
