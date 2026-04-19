import {
  createGatewayApiClient,
  gatewayEndpointPaths,
  gatewayExecutionStatuses,
  milestoneCheckpoints,
  type CreateCheckpointRequest,
  type CreateWorkflowRequest,
  type GatewayExecutionStatus,
  type MilestoneCheckpointTag,
  type TransitionExecutionStatusRequest
} from "../../../packages/contracts/src/index";

const workflowRequest: CreateWorkflowRequest = {
  workflowToml: 'version = "0.1.0"'
};

const checkpointRequest: CreateCheckpointRequest = {
  tag: "cp/01-contracts-frozen",
  summary: "Contracts locked for parallel lanes"
};

const executionStatus: GatewayExecutionStatus = "queued";
const milestoneTag: MilestoneCheckpointTag = milestoneCheckpoints[1].tag;

const transitionRequest: TransitionExecutionStatusRequest = {
  status: executionStatus,
  message: `Moved to ${executionStatus}`,
  metadata: { lane: "contracts" }
};

const client = createGatewayApiClient({
  baseUrl: "http://127.0.0.1:8088",
  fetch: async () =>
    new Response(
      JSON.stringify({
        service: "api-gateway",
        status: "ok",
        repositoryBackend: "FileGatewayRepository",
        storeRoot: "/tmp/juliaflow",
        workflowCount: 1,
        checkpointCount: 1,
        executionCount: 0
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" }
      }
    )
});

client.healthcheck();
client.createWorkflow(workflowRequest);
client.createCheckpoint(checkpointRequest);
client.transitionExecutionStatus("exec-1", transitionRequest);

gatewayEndpointPaths.workflowDetail("foundation/workflow");
gatewayEndpointPaths.executionStatus("exec-1");
gatewayExecutionStatuses satisfies readonly GatewayExecutionStatus[];
milestoneTag satisfies MilestoneCheckpointTag;
