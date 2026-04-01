using UnityEngine;

public class PlayerCameraController : MonoBehaviour
{
    [SerializeField] private Transform _playerTransform;

    private void LateUpdate()
    {
        transform.position = _playerTransform.position;
    }
}
