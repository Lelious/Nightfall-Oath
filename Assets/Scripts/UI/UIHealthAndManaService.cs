using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class UIHealthAndManaService : MonoBehaviour
{
    [SerializeField] private Image _hpBar;
    [SerializeField] private Image _mpBar;
    [SerializeField] private Image _expBar;
    [SerializeField] private TextMeshProUGUI _expText;
    [SerializeField] private TextMeshProUGUI _healthText;
    [SerializeField] private TextMeshProUGUI _manaText;
    [SerializeField] private Light _dirLight;

    private Material _hpMaterial;
    private Material _manaMaterial;
    private Material _expMaterial;

    private float _exp;

    private void Awake()
    {
        _hpMaterial = new Material(_hpBar.material);
        _hpBar.material = _hpMaterial;
        _manaMaterial = new Material(_mpBar.material);
        _mpBar.material = _manaMaterial;
        _manaMaterial.SetFloat("_NoiseOffset", 0.5f);
        _expMaterial = new Material(_expBar.material);
        _expBar.material = _expMaterial;
        Enemy.OnEnemyDeath += IncreaseExp;
    }

    public void SetDay()
    {
        _dirLight.intensity = 1.0f;
    }

    public void SetNight()
    {
        _dirLight.intensity = 0.1f;
    }

    public void UpdateHealth(float currentHealth, float maxHealth)
    {
        var currentHp = Mathf.RoundToInt(currentHealth < 0 ? 0 : currentHealth);
        _hpMaterial.SetFloat("_Fill", currentHp / maxHealth);
        _healthText.text = $"{currentHp} / {Mathf.RoundToInt(maxHealth)}";
    }

    public void UpdateMana(float currentMana, float maxMana)
    {
        _manaMaterial.SetFloat("_Fill", currentMana / maxMana);
        var currentHp = Mathf.RoundToInt(currentMana < 0 ? 0 : currentMana);
        _healthText.text = $"{currentMana} / {Mathf.RoundToInt(maxMana)}";
    }

    private void IncreaseExp()
    {
        _exp += 5f;
        var diff = Mathf.Clamp01(_exp / 100f);
        _expMaterial.SetFloat("_Fill", diff / 2f);
        _expText.text = $"{(int)(_exp)}%";
    }
}
