using System;
using TMPro;
using UniRx;
using UnityEngine;
using UnityEngine.UI;
using Zenject;

public class EnemyHealthInfoPannel : MonoBehaviour, IDisposable
{
    [SerializeField] private GameObject _healthPannel;
    [SerializeField] private Image _healthBar;
    [SerializeField] private GameObject _eliteIcon;
    [SerializeField] private TextMeshProUGUI _name;
    [SerializeField] private TextMeshProUGUI _health;
    [SerializeField] private Button _cancelButton;
    [SerializeField] private Transform _targetFramePrefab;
    [SerializeField] private Material _targetFrameMaterial;

    private readonly CompositeDisposable _disposables = new();
    private Transform _frame;
    private InputService _inputService;
    private HealthComponent _healthComponent;
    

    [Inject]
    public void Construct(InputService inputService)
    {
        _inputService = inputService;
        _cancelButton.onClick.AddListener(StartAutotarget);
        _frame = Instantiate(_targetFramePrefab);
        _frame.SetParent(_healthPannel.transform);
    }

    public void InitializeEnemyHealth(Enemy enemy, bool autoTarget)
    {
        _disposables?.Clear();

        if (enemy == null)
        {
            HidePannel();
            return;
        }

        _healthComponent = enemy.GetHealth();

        if (_healthComponent != null)
        {
            Observable.CombineLatest(_healthComponent.CurrentHp, _healthComponent.MaxHp, (current, max) => (current, max)).
                Subscribe(value => UpdatePannelInformation(value.current / value.max, $"{Mathf.RoundToInt(value.current)} / {Mathf.RoundToInt(value.max)}")).
                AddTo(_disposables);

            _cancelButton.gameObject.SetActive(!autoTarget);
            _targetFrameMaterial.SetFloat("_Selected", autoTarget ? 0f : 1.0f);

            Observable.EveryUpdate().
                TakeWhile(_ => enemy != null).
                Subscribe(_ => _frame.transform.position = enemy.transform.position).
                AddTo(_disposables);
        }

        _healthPannel.SetActive(enemy != null);

        if (enemy == null)
            return;
        
        var data = enemy.GetData();
        var elite = data.Elite == true ? " Elite" : "";
        _name.text = $"{data.Name} (Level {data.Level}) {elite}";
        _eliteIcon.SetActive(data.Elite);
        _frame.localScale = data.FrameScale * Vector3.one;
    }

    public void HidePannel()
    {
        _healthPannel.SetActive(false);
    }

    private void StartAutotarget()
    {
        _inputService.CancelTarget();
    }

    private void UpdatePannelInformation(float health, string textHP)
    {
        _healthBar.fillAmount = health;
        _health.text = textHP;
    }

    public void Dispose()
    {
        _disposables.Dispose();
    }
}
