using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

public class AvoidanceService : MonoBehaviour
{
    public float avoidRadius = 1.2f;
    public float avoidStrength = 2f;
    public float maxSpeed = 3.5f;

    [SerializeField] private List<NavMeshAgent> _allAgents = new();

    void FixedUpdate()
    {
        foreach (var agent in _allAgents)
        {
            if (agent == null) continue;

            Vector3 avoidance = CalculateAvoidance();

            Vector3 desiredVelocity = agent.desiredVelocity;
            Vector3 finalVelocity = desiredVelocity + avoidance;

            finalVelocity = Vector3.ClampMagnitude(finalVelocity, maxSpeed);

            agent.velocity = finalVelocity;
        }
    }

    private Vector3 CalculateAvoidance()
    {
        Vector3 force = Vector3.zero;

        foreach (var other in _allAgents)
        {
            if (other == null) continue;

            Vector3 diff = transform.position - other.transform.position;
            float dist = diff.magnitude;

            if (dist < avoidRadius && dist > 0.001f)
            {
                float strength = (avoidRadius - dist) / avoidRadius;
                force += diff.normalized * strength;
            }
        }

        return force * avoidStrength;
    }
}
