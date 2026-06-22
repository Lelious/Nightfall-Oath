using System.Runtime.CompilerServices;
using Unity.Burst;
using Unity.Mathematics;

namespace LeliousExtentions
{
    public static class LeliousMathematic
    {
        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static bool FlatDistanceGreaterThan(float2 pos1, float2 pos2, float distance)
        {
            return math.distancesq(pos1, pos2) > (distance * distance);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static bool DistanceGreaterThan(float3 pos1, float3 pos2, float distance)
        {
            return math.distancesq(pos1, pos2) > (distance * distance);
        }

        [MethodImpl(MethodImplOptions.AggressiveInlining)]
        public static bool GridDistanceGreaterThan(int2 pos1, int2 pos2, int distance)
        {
            int2 delta = math.abs(pos1 - pos2);
            return delta.x > distance || delta.y > distance;
        }
    }
}
