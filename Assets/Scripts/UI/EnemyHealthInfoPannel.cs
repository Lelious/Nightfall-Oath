using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class EnemyHealthInfoPannel : MonoBehaviour
{
    [SerializeField] private GameObject _healthPannel;
    [SerializeField] private Image _healthBar;
    [SerializeField] private GameObject _eliteIcon;
    [SerializeField] private TextMeshProUGUI _name;
    [SerializeField] private TextMeshProUGUI _health;
    [SerializeField] private TargetFinderComponent _targetFinder;
    [SerializeField] private Button _cancelButton;

    private HealthComponent _healthComponent;

    private void Awake()
    {
        _cancelButton.onClick.AddListener(StartAutotarget);
    }

    public void InitializeEnemyHealth(Enemy enemy, bool autoTarget)
    {
        if (_healthComponent != null)
            _healthComponent.OnHealthChanged -= UpdatePannelInformation;

        _healthPannel.SetActive(enemy != null);

        if (enemy == null)
            return;
        
        var data = enemy.GetData();
        var elite = data.Elite == true ? " Elite" : "";
        _name.text = $"{data.Name} (Level {data.Level}) {elite}";
        _eliteIcon.SetActive(data.Elite);   

        _healthComponent = enemy.GetHealth();
        _healthComponent.OnHealthChanged += UpdatePannelInformation;
        _cancelButton.gameObject.SetActive(!autoTarget);
        UpdatePannelInformation(_healthComponent.GetCurrentHealth());
    }

    public void HidePannel()
    {
        _healthPannel.SetActive(false);
    }

    private void StartAutotarget()
    {
        _targetFinder.SetAutotargetMode(true);
    }

    private void UpdatePannelInformation(float health)
    {
        var hp = _healthComponent.GetCurrentHealth();
        var maxHealth = _healthComponent.GetMaxHealth();
        _healthBar.fillAmount = hp / maxHealth;
        var currentHp = Mathf.RoundToInt(hp < 0 ? 0 : hp);
        _health.text = $"{currentHp}/{Mathf.RoundToInt(maxHealth)}";
    }
}
