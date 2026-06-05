using UnityEngine;

public class PlayerCameraController : MonoBehaviour
{
    private Transform _playerTransform;

    public void SetHeroTransform(Transform heroTransform)
    {
        _playerTransform = heroTransform;
    }

    private void LateUpdate()
    {
        if (_playerTransform == null) return;
        transform.position = _playerTransform.position;
    }
}
