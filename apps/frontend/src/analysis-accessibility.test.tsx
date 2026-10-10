import { cleanup, render, screen, within } from "@testing-library/react";
import { afterEach, expect, it } from "vitest";
import { AnalysisEvidenceTables } from "./components/AnalysisEvidenceTables";

afterEach(cleanup);
it("exposes saved units, complete-pair counts and unavailable values without recomputing or relabeling them", () => {
  render(<AnalysisEvidenceTables evidence={{
    numericColumns:["area","price"],correlationMatrix:[[1,null],[null,1]],correlationPairCounts:[[4,2],[2,3]],
    scatter:{xColumn:"area",yColumn:"price",xLabel:"Area (m²)",yLabel:"Price (<USD>)",x:[0,1e-200],y:[10,20]},
    distribution:{column:"area",label:"Area (m²)",values:[0,1e-200,4]}
  }} />);
  const correlation=screen.getByRole("table",{name:"Pearson correlations and complete-pair counts",hidden:true});
  const comparison=within(correlation).getAllByRole("row",{hidden:true})[2];
  expect(within(comparison).getAllByRole("cell",{hidden:true}).map((cell) => cell.textContent)).toEqual(["Column 1","Column 2","unavailable","2"]);
  expect(screen.getByRole("table",{name:"Correlation column key",hidden:true})).toHaveTextContent("Column 1areaColumn 2price");
  const scatter=screen.getByRole("table",{name:"Selected complete scatter pairs",hidden:true});
  expect(scatter).toHaveTextContent("Area (m²)Price (<USD>)");
  expect(scatter).toHaveTextContent("1e-200");
  expect(within(scatter).getAllByRole("row",{hidden:true})).toHaveLength(3);
  expect(screen.getByRole("region",{name:"Selected complete scatter pairs",hidden:true})).toHaveAttribute("tabindex","0");
  expect(screen.getByRole("table",{name:"Selected finite distribution values",hidden:true})).toHaveTextContent("0");
  expect(screen.getByText(/Histogram bins|histogram bins/)).toBeInTheDocument();
});
it("reports presentation limits without rendering amplified names or changing evidence", () => {
  const evidence={numericColumns:Array.from({length:16},(_,i)=>`${i}-${"x".repeat(8192)}`)};
  const before=JSON.stringify(evidence);
  render(<AnalysisEvidenceTables evidence={evidence} />);
  expect(screen.getByRole("status")).toHaveTextContent("presentation limit");
  expect(screen.queryByRole("table",{hidden:true})).not.toBeInTheDocument();
  expect(JSON.stringify(evidence)).toBe(before);
});
