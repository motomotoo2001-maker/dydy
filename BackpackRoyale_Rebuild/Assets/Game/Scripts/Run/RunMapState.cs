using System.Collections.Generic;

namespace BackpackRoyale.Rebuild
{
    public sealed class RunMapState
    {
        private readonly List<RunNode> nodes;
        private readonly HashSet<string> completedNodeIds = new HashSet<string>();

        public IReadOnlyList<RunNode> Nodes => nodes;
        public IReadOnlyCollection<string> CompletedNodeIds => completedNodeIds;
        public int MaxStage { get; }

        public RunMapState(List<RunNode> valueNodes, int maxStage)
        {
            nodes = valueNodes ?? new List<RunNode>();
            MaxStage = maxStage;
        }

        public IReadOnlyList<RunNode> GetChoicesForStage(int stage)
        {
            var result = new List<RunNode>();
            for (int i = 0; i < nodes.Count; i++)
                if (nodes[i].Stage == stage)
                    result.Add(nodes[i]);
            return result;
        }

        public RunNode FindById(string id)
        {
            if (string.IsNullOrEmpty(id))
                return null;
            for (int i = 0; i < nodes.Count; i++)
                if (nodes[i].Id == id)
                    return nodes[i];
            return null;
        }

        public void MarkCompleted(RunNode node)
        {
            if (node != null && !string.IsNullOrEmpty(node.Id))
                completedNodeIds.Add(node.Id);
        }

        public void MarkCompleted(string nodeId)
        {
            if (!string.IsNullOrEmpty(nodeId) && FindById(nodeId) != null)
                completedNodeIds.Add(nodeId);
        }

        public bool IsCompleted(RunNode node) => node != null && completedNodeIds.Contains(node.Id);
    }
}
