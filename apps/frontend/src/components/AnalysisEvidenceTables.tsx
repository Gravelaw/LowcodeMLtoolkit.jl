import { DataTable } from "./ui";

const values = (value: unknown): unknown[] => Array.isArray(value) ? value : [];
const number = (value: unknown) => typeof value === "number" && Number.isFinite(value) ? value : "unavailable";

/** Read the saved run directly; never recompute or borrow current schema labels. */
export function AnalysisEvidenceTables({ evidence }: { evidence: Record<string, unknown> }) {
  const columns = values(evidence.numericColumns).map(String);
  const scatter = evidence.scatter as Record<string, unknown> | undefined;
  const distribution = evidence.distribution as Record<string, unknown> | undefined;
  const labelSize = [...columns,String(scatter?.xLabel ?? scatter?.xColumn ?? ""),String(scatter?.yLabel ?? scatter?.yColumn ?? ""),String(distribution?.label ?? distribution?.column ?? "")]
    .reduce((size, label) => size + new TextEncoder().encode(label).byteLength, 0);
  const rowCount = columns.length + columns.length * (columns.length + 1) / 2 + values(scatter?.x).length + values(distribution?.values).length;
  if (labelSize > 65536 || rowCount > 5000) return <p role="status">Structured chart tables unavailable: this saved evidence exceeds the presentation limit of 64 KiB of UTF-8 labels or 5,000 rows. Immutable evidence is unchanged; its result reference remains in saved run history.</p>;
  const correlations = values(evidence.correlationMatrix);
  const counts = values(evidence.correlationPairCounts);
  const pairs = columns.flatMap((column, i) => columns.slice(i).map((_, offset) => ({
    key: `${i}-${i + offset}`, column: `Column ${i + 1}`, other: `Column ${i + offset + 1}`,
    correlation: number(values(correlations[i])[i + offset]),
    count: number(values(counts[i])[i + offset])
  })));
  const x = values(scatter?.x), y = values(scatter?.y);
  const points = x.map((value, i) => ({ pair: i + 1, x: number(value), y: number(y[i]) }));
  const observations = values(distribution?.values).map((value, i) => ({ observation: i + 1, value: number(value) }));
  return <div className="analysis-chart-data">
    <details><summary>Correlation table and valid pair counts</summary>
      <DataTable caption="Correlation column key" columns={[{key:"key",label:"Key"},{key:"name",label:"Saved column name"}]} rows={columns.map((name,i) => ({key:`Column ${i + 1}`,name}))} getRowKey={(row) => row.key} />
      <DataTable caption="Pearson correlations and complete-pair counts" columns={[{key:"column",label:"Column"},{key:"other",label:"Compared column"},{key:"correlation",label:"Pearson r"},{key:"count",label:"Valid pairs"}]} rows={pairs} getRowKey={(row) => row.key} />
      <p>Unavailable correlations include constant or unqualified numeric ranges. Association does not establish cause.</p>
    </details>
    {scatter ? <details><summary>Scatter data table</summary>
      <DataTable caption="Selected complete scatter pairs" columns={[{key:"pair",label:"Pair"},{key:"x",label:String(scatter.xLabel ?? scatter.xColumn)},{key:"y",label:String(scatter.yLabel ?? scatter.yColumn)}]} rows={points} getRowKey={(row) => String(row.pair)} />
      <p>Pair numbers identify the saved chart sequence, not source row identifiers. Only pairs with both finite values are included.</p>
    </details> : null}
    {distribution ? <details><summary>Distribution data table</summary>
      <DataTable caption="Selected finite distribution values" columns={[{key:"observation",label:"Observation"},{key:"value",label:String(distribution.label ?? distribution.column)}]} rows={observations} getRowKey={(row) => String(row.observation)} />
      <p>These are the saved observations; histogram bins are chosen by the chart renderer. Observation numbers are not source row identifiers.</p>
    </details> : null}
  </div>;
}
