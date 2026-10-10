import { DataTable } from "./ui";

const values = (value: unknown): unknown[] => Array.isArray(value) ? value : [];
const number = (value: unknown) => typeof value === "number" && Number.isFinite(value) ? value : "unavailable";

/** Read the saved run directly; never recompute or borrow current schema labels. */
export function AnalysisEvidenceTables({ evidence }: { evidence: Record<string, unknown> }) {
  const columns = values(evidence.numericColumns).map(String);
  const correlations = values(evidence.correlationMatrix);
  const counts = values(evidence.correlationPairCounts);
  const pairs = columns.flatMap((column, i) => columns.slice(i).map((other, offset) => ({
    key: `${i}-${i + offset}`, column, other,
    correlation: number(values(correlations[i])[i + offset]),
    count: number(values(counts[i])[i + offset])
  })));
  const scatter = evidence.scatter as Record<string, unknown> | undefined;
  const x = values(scatter?.x), y = values(scatter?.y);
  const points = x.map((value, i) => ({ pair: i + 1, x: number(value), y: number(y[i]) }));
  const distribution = evidence.distribution as Record<string, unknown> | undefined;
  const observations = values(distribution?.values).map((value, i) => ({ observation: i + 1, value: number(value) }));
  return <div className="analysis-chart-data">
    <details><summary>Correlation table and valid pair counts</summary>
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
