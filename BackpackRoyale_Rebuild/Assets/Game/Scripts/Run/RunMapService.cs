using System;
using System.Collections.Generic;

namespace BackpackRoyale.Rebuild
{
    public sealed class RunMapService
    {
        private readonly int seed;

        public RunMapService(int valueSeed)
        {
            seed = valueSeed;
        }

        public RunMapState Generate(int stages)
        {
            int maxStage = Math.Max(2, stages);
            var nodes = new List<RunNode>
            {
                new RunNode("stage_1_battle", 1, RunNodeType.Battle, "Opening Battle")
            };

            var random = new Random(seed);
            for (int stage = 2; stage < maxStage; stage++)
            {
                bool eliteFirst = random.Next(0, 2) == 0;
                RunNode battle = new RunNode($"stage_{stage}_battle", stage, RunNodeType.Battle, $"Battle {stage}");
                RunNode elite = new RunNode($"stage_{stage}_elite", stage, RunNodeType.Elite, $"Elite {stage}");
                if (eliteFirst)
                {
                    nodes.Add(elite);
                    nodes.Add(battle);
                }
                else
                {
                    nodes.Add(battle);
                    nodes.Add(elite);
                }
            }

            nodes.Add(new RunNode($"stage_{maxStage}_boss", maxStage, RunNodeType.Boss, "Final Boss"));
            return new RunMapState(nodes, maxStage);
        }
    }
}
