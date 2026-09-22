Problem: 데이터를 보기 전에도 알 수 있는, "이 문제가 왜 어려운가"에 대한 배경 설명

key finding
데이터에서 뭘 봤는지가 아니라, "그 발견이 왜 중요하고, 어떤 의사결정으로 이어지는지"가 들어가야 함!!
- 구체적 수치가 있는가
- 의사결정과 연결되는가? 그 발견 때문에 그래서 우리가 뭘 다르게 해야 하는가까지 이어져야 함
- 분석 없이는 몰랐을 내용인가 - raw 데이터를 슬쩍 봐도 알수있는 당연한 사실이 아니라 분석을 거쳐야만 드러나는 인사이트여야 함.


# 이벤트 로그 기반 수리 서비스 리드타임 분석 및 개선 시뮬레이션
수리 프로세스 이벤트 로그를 기반으로 리드타임 지연의 원인을 규명하고, 우선순위 스케줄링 · 병목 개선 · Resource 재배분 정책을 Simpy로 시뮬레이션하여 운영 개선안을 도출한 프로젝트입니다.

📄 분석 과정 전체(시각화 포함)는 포트폴리오 PDF 에 정리되어 있습니다. 이 문서는 프로젝트 요약이며, 코드와 설계 의사결정 과정은 notebooks/에서 확인하실 수 있습니다.

#### 핵심 결과
| 지표 | 결과 |
| -- | -- |
| 전체 평균 리드타임 | **70.6h → 37.5h (▼46.9%)** |
| 핵심 병목 `Inform Client Survey → Survey` | **41.52h → 8.37h (▼79.8%)** |
| 담당자 간 대기시간 편차 | **48.01h → 8.87h (▼81.5%)** |
| 공정 내 묶인 자본 | **8.09억 원 → 4.53억 원 (▼3.56억 원)** |

## 🎯 Analysis Objective
> **"리드타임을 단축하면서 제한된 운영 자원을 어디에, 어떤 기준으로 배분해야 하는가?"**

특정 공정의 작업시간만 줄이는 것이 아니라,
- 전체 리드타임
- 핵심 병목 구간
- 비즈니스 영향이 큰 Case
- 담당자별 Resource 편차

를 함께 고려하여 시뮬레이션 효과 비교

## 🔑 Key Findings
> **병목의 핵심은 수리 작업 자체의 처리 속도보다, 작업과 작업 사이에서 Case가 정체되는 Queue 구조**

**1. 대기시간이 리드타임을 지배하며, 병목은 특정 구간에 집중되어 있습니다.**
전체 리드타임의 93.9%가 공정 간 대기 시간에서 발생하고, 그중 `Inform Client Survey → Survey` 구간이 평균 3.2일(76.8시간)로 가장 큰 병목입니다. 

→ 작업 속도 개선보다 대기 구조 자체를 줄이는 개입이 우선되어야 합니다.

**2. 재수리는 케이스당 지연 폭은 크지만, 발생 빈도는 낮은 국소적 이슈입니다.**
내부 반복 수리(`Intern → Intern`) 시퀀스는 케이스당 평균 1.36일의 추가 지연을 유발하지만, 실제 발생 빈도는 12.7%(127건)에 그칩니다. 

→ 전체 프로세스 재설계보다 해당 케이스만 타겟팅하는 개입이 더 효율적입니다.

**3. 현재 우선순위 체계는 실제 영향도를 반영하지 못하고 있습니다.**
서비스 우선순위·고장 심각도는 실제 처리 순서에 반영되지 않으며, 그럼에도 상위 20% 케이스가 전체 영향의 48.3%를 차지합니다. 

→ 영향도 기반의 명시적 우선순위 스코어링 체계가 필요하다는 근거가 됩니다.

**4. 내부 수리 SLA는 외주 대비 두 배 가까이 붕괴되어 있습니다.**
내부 수리 SLA 실패율은 27.8%로 외주(14.4%)의 약 2배이며, 이 차이는 통계적으로 유의합니다(카이제곱, p=0.0316). 

→ 내부 수리 프로세스가 우선 개선 대상

## 📌 Project Overview
1,000건의 수리 케이스에서 발생한 이벤트 로그를 기반으로 **왜 리드타임이 증가하는지** 분석하고, 어떤 운영 정책이 실제 개선으로 이어질 수 있는지 검증했습니다.

이벤트 로그를 분석한 결과, 실제 수리 작업보다 **공정 간 Waiting Time이 리드타임에 훨씬 큰 영향을 미치며**, 특히 `Inform Client Survey → Survey` 구간에 대기가 집중되어 있음을 확인했습니다.

이러한 대기가 발생하는 운영상의 원인을 충분히 설명하기 어렵다는 점을 보완하기 위해, 가상 변수를 생성하여 가설 검증을 통해 지연 원인을 구체화하고
Priority Scheduling → Bottleneck Capacity → Integrated Resource Model 순으로 분석을 확장하여 운영 정책별 개선 효과를 비교했습니다.

# 🚨 Problem
- **과도한 리드타임 지연** : 고객 접수부터 서비스 완료까지 일부 케이스에서 리드타임이 과도하게 증가하는 현상 발생

- **원인 규명 지표 부재** : 이벤트 로그만으로는 "무엇이 일어났는지"는 알 수 있어도 "왜 지연되는지"는 설명하기 어려움 / 지연 원인이 특정 공정 문제인지, 운영 프로세스 구조 전반의 문제인지 데이터 기반 검증 필요

- **비즈니스 리스크 증대** : 지연 발생 시 소수의 고가치 Case에 리스크가 집중될 가능성

#### Project Information
- 기간 : 2026.05 ~ 2026.08
- 역할 : 개인 프로젝트(데이터 전처리, 통계 가설 검증, 시각화, 시뮬레이션 설계)
- Tools : Python (Pandas, Statsmodels, Scipy, Simpy), MySQL, Tableau

#### 📂 Dataset
분석에 활용된 수리 프로세스 이벤트 로그 구성
CaseID를 기준으로 하나의 수리 요청에 여러 task 이벤트가 연결되는 구조

| 컬럼명 | 설명 |
| :--- | :--- |
| caseID | 수리 요청 건별 고유 식별자 |
| taskID | 세부 공정 단계 (ex : Inform Client Survey, Survey, InternRepair) |
| originator | 해당 공정을 수행한 담당자 |
| eventtype | 작업 이벤트 유형(Start / Complete) |
| timestamp | 이벤트 발생 시각 |
| contact | 접수 수단(Phone, Personal) |
| RepairType | 수리 유형 |
| RepairInternally | 자사 수리 가능 여부(True/False) |
| EstimatedRepairTime | 접수 시점에 산정된 예상 수리 시간(분) |
| RepairCode | 수리코드(1.0 ~ 4.0) |
| RepairOK | 수리 종료 여부(True/False) |


## 🔄 Approach
#### 1. Data Understanding
- 1,000건의 수리 이벤트 로그 구조 및 데이터 품질 검증
- Start < Complete 선후관계 검증
- 단독 Task(고객 정보 오류)는 예외 케이스 처리

#### 2. Process & Bottleneck Analysis
- 프로세스 맵 구조화
- Task 간 Waiting Time 분석
- 재수리 및 담당자 전환 패턴 분석

#### 3. Feature Engineering & Hypothesis Testing
- True Waiting Time 등 핵심 파생 변수 생성
- 도메인 기반 프록시 변수 설계
- 4가지 가설 통계 검증
- Case 별 비용 집중도 분석(파레토 분석)

#### 4. Simulation
- 우선순위 스케줄링 × 병목 Capacity × 담당자 Resource 재배분을 결합한 5가지 시나리오(A~E)를 SimPy 기반으로 비교


## ⚙️ Feature Engineering
비즈니스 영향을 분석하기 위해 산출한 주요 파생 변수

#### 파생변수
| 변수명 | 정의 및 목적 |
| --- | --- |
| True Waiting Time | 순수 작업 시간을 제외하고 공정 간 멈춰있는 실질 대기시간 산출 |
| Handover Type | 이관 유형 분류(```System ➔ Human```, ```Human ➔ Human``` 등) |
| Repair Type | 내부/외부 수리 유형 구분 |
| Repair Mode | 단일/다중 수리 유형 구분 |
| Locked Capital | 공정 내 지연으로 인해 묶여 있는 자본 규모 |


#### 도메인 기반 가상 변수
| 변수명 | 정의 및 목적 |
| --- | --- |
| ```product_category``` | 제품군별(대형가전, IT 가전 등) 지연 패턴 차이 분석을 위한 범주 |
| ```product_price``` | 제품 가격 |
| ```priority``` | Case의 비즈니스 영향 및 운영 리스크를 기준으로 분류한 우선순위(High / Medium / Low) |
| ```failure_severity``` | 접수 시점에 알 수 있는 정보만으로 산정한 고장 심각도(High / Medium / Low) |
| ```repair_cost``` | 수리 비용 |
| ```SLA_breach``` | 약정 서비스 수준 계약 위반 여부 — 입력이 아닌 시뮬레이션 결과 평가용 지표로만 사용 |

> 💡 Core Insight : 본 프로젝트에서는 원본 이벤트 로그에서 확인할 수 없는 운영 특성을 보완하기 위해 도메인 가정 기반의 프록시 변수를 설계했습니다. 가상 변수는 변수 간 인과성이 결과를 사전에 결정하지 않도록 확률적 요소를 적용하여 설계했으며, 가설 검증과 정책 시뮬레이션을 위한 분석용 변수로 사용했습니다. 따라서 해당 변수 및 시뮬레이션 결과는 실제 운영 환경의 실측값이 아니며, 실제 적용을 위해서는 현업 운영 데이터 기반의 추가 검증이 필요합니다.


## 🧪 Hypothesis Testing
#### Hypothesis 1. 재수리 발생은 Schedule Compliance 실패와 관련이 있는가?
> 재수리는 Schedule Compliance 실패와 강하게 관련되지만, 전체 대기시간의 핵심 원인으로는 보기 어려움.
- 재수리 Case에서 Schedule Compliance 저하 확인
- 그러나 재수리 발생 비중이 낮아 전체 Lead Time에 미치는 영향은 제한적
- 따라서 재수리는 국소적 개선 과제로 분류

#### Hypothesis 2. 제품 특성이 Lead Time에 영향을 미치는가?
> 제품 가격과 Lead Time 간 유의한 관계를 확인하지 못함
- 제품 특성보다 공통 프로세스의 Waiting 구조가 핵심 지연 요인으로 판단
- OLS 회귀분석 p = 0.667

#### Hypothesis 3. 외부 위탁 수리는 내부 수리 대비 SLA 실패의 핵심 요인인가?
> 외주보다 내부 수리의 SLA 리스크가 높음
- 외주 SLA 실패율: `14.4%`
- 내부 SLA 실패율: `27.8%`
- Chi-square test: `p = 0.0316`
- 외주 축소보다 **내부 수리 공정의 SLA 관리 개선을 우선**

#### Hypothesis 4. 우선순위와 고장심각도가 실제 운영에 활용되고 있는가?
> Priority·Severity 모두 현재 Queue Scheduling에 충분히 반영되지 않음
- Priority별 SLA / Waiting Time 차이가 크지 않음
- Severity별 대기시간 분포도 유사
- 고위험 Case를 별도로 우선 처리하는 구조가 부족

> → 접수 시점 정보를 활용한 **Dynamic Priority Score 설계**


## 📈 Simulation & Impact
Event Log는 이미 발생한 운영 결과를 보여주기 때문에, 정책 변경 이후의 결과를 직접 관찰할 수 없습니다.

따라서 SimPy 기반 Discrete Event Simulation을 구축하여 운영 정책별 효과를 비교했습니다.

### 3 Simulation Evolution

```text
Attempt 1
Priority Scheduling 우선순위 스케줄링
        ↓
Attempt 2
Bottleneck Capacity 병목 Capacity 확대
        ↓
Attempt 3
Integrated Resource Model 담당자 업무 구조 반영 Resource 재배분
```


#### Scenario E — Integrated Resource Model
 단계적으로 검증한 결과, 담당자의 실제 겸직 구조를 반영한 **Scenario E**에서 가장 효과적인 개선 성과를 확인했습니다.

| 지표 | 개선 전 | 개선 후 (Scenario E) |
|----------|----------|-----------|
| 전체 리드타임 | 70.6h | 37.5h (**▼46.9%**) |
| 핵심 병목 구간(Inform → Survey) | 41.52h | 8.37h (**▼79.8%**) |
| VIP 리드타임 | 67.05h | 42.28h (**▼36.9%**) |
| 공정 내 동결 자본 | 8.09억 원 | 4.53억 원 (**▼3.56억 원 조기 회수**) |
| 담당자 간 대기시간 편차 | 48.01h | 8.87h (**▼81.5%**)

※ Scenario E는 실제 운영 결과가 아닌,
Event Log와 설정한 운영 가정을 기반으로 한 Simulation 결과

$$\text{Priority Score} = \text{MinMax (Business Value)} * \text{MinMax(Operational Risk)}$$

- **Business Value** : 수리 단가를 기준으로 산정한 접수 시점의 예상 수리비
- **Operational Risk** : 제품 카테고리를 기반으로 사전 추정한 고장 심각도
- 재수리 횟수, 외주 가산비 등 케이스 종료 후 확정되는 사후 정보는 제외하고, 접수 시점에 판단 가능한 정보만 사용


> 💡 Core Insight : 순서만 바꾸거나(Attempt 1) 용량만 늘리는 것(Attempt 2)만으로는 부족했고, 담당자의 실제 업무 구조까지 반영한 통합 모델(Attempt 3)에서 비로소 유의미한 개선이 나타났습니다.

#### Attempt 1 — Priority Scheduling
> 처리 순서에 Priority를 적용하여 처리 순서만 변경했을 때 어느 정도 개선되는가?
  - 비즈니스 영향이 큰 VIP 리드타임만 개선될 뿐, 시스템 전체 리드타임 개선에는 한계

#### Attempt 2 — Bottleneck Capacity
> 병목 자체의 처리 능력을 높였을 때 전체 Lead Time이 얼마나 감소하는가?
  - Inform → Survey 구간의 Survey 담당 Resource 분석 결과, 자격 보유 인원은 많지만 실제 동시 투입 인원은 제한적
    - Survey 자격 보유 Resource: 11명
    - 관측된 동시 투입 수준: 약 3명
    - Capacity 3명 기준 가동률: 114%
    - Capacity 5명 기준 가동률: 약 68%
  - 단순 Capacity 확대만으로는 실측 대기시간을 충분히 설명하지 못함

#### Attempt 3 — Integrated Resource Model
> 실제 담당자 업무 구조까지 반영하면 추가 개선이 가능한가?
- 자격 보유 인원 ≠ 실제 해당 업무에 투입 가능한 Resource — 담당자는 Survey 외 다른 업무도 병행하기 때문
- 담당자의 실제 업무 구조(겸직 여부·업무량)를 반영해 전체 병목과 담당자 간 편차를 함께 개선하도록 Resource 배분 구조를 재설계


## 📋 Recommendations
  **1. 데이터 기반 우선순위 스케줄링 도입**
  접수 시점에 추정 가능한 Business Value와 Operational Risk를 기반으로 Case별 Priority를 산정하고 Queue에 반영합니다. → 비즈니스 영향이 큰 Case의 대기 리스크를 관리합니다.

  **2. `Inform Client Survey → Survey` 공정 Capacity 확대**
  핵심 병목의 Queue와 담당 Resource를 모니터링하고, 피크 상황에서는 기존 자격 보유 인력을 유연하게 배치합니다. → 구조적 Queue 누적을 방지합니다.

  **3. 담당자 업무량 기반 Resource 재배분**
  담당자의 겸직 여부와 현재 업무량을 고려하여 특정 담당자에게 업무가 집중되지 않도록 Resource를 재배분합니다. → 담당자 간 대기시간 편차를 완화합니다.

  **4. 국소 병목(재수리·외주 공정) 운영 가이드라인 정립**
  재수리 및 외주 공정은 개별 Case의 SLA 및 지연 리스크를 줄이기 위한 SOP와 모니터링 기준을 마련합니다. → 재수리·외주 지연 50% 단축 가정 시 전체 리드타임 최대 ▼0.66h 개선 효과가 있습니다.

시행착오 -> notebooks/repair_process_analysis.ipynb (제거 고민)


## 📊 Tableau Dashboard Preview
🔗 **[Tableau Public에서 실시간 대시보드 조작해보기](여기에_태블로_퍼블릭_링크)**

####  Dash1 - 현황 진단: 전체 프로세스 및 리드타임 구조

#### Dash2 - 병목 구간 분석: Waiting Time 및 담당자 전환 분석

#### Dash3 - 시뮬레이션 결과: 시나리오별 개선 효과 비교


## 📁 Structure <- github 폴더와 일치하는지 확인!!
├── data/                # 원본 및 전처리 데이터 (caseID 기준 이벤트 로그)
├── notebooks/           # EDA, 가설 검증, 시뮬레이션 노트북 (.ipynb)
├── src/                 # 파생 변수 생성, 통계 검정, 시뮬레이션 함수 (.py)
└── outputs/             # 대시보드 캡처 및 분석 리포트 결과물


repair-process-analysis/
│
├── README.md
│
├── data/
│   └── README.md
│
├── notebooks/
│   ├── 01_process_eda.ipynb
│   ├── 02_bottleneck_analysis.ipynb
│   ├── 03_hypothesis_testing.ipynb
│   ├── 04_simulation.ipynb
│   └── 05_improvement_strategy.ipynb
│
├── src/
│   ├── preprocessing.py
│   ├── process_analysis.py
│   └── simulation.py
│
└── outputs/
    ├── process_flow.png
    ├── lead_time_distribution.png
    ├── bottleneck_analysis.png
    ├── hypothesis_results.png
    └── simulation_results.png


## ⚠️ Limitations
- 모든 프록시 변수(product_price, priority, failure_severity 등)는 실제 운영 데이터가 아닌 도메인 리서치 기반 가정치입니다.
- 시뮬레이션으로 개선 효과를 사전 검증했으나, 실제 운영 데이터를 통한 사후 검증(A/B Test)은 수행하지 못했습니다.
- Scenario E의 개선 효과 역시 실제 운영에 정책을 적용한 결과가 아니라
Event Log와 설정한 운영 가정을 기반으로 한 Simulation 결과

실제 적용을 위해서는

1. 실제 운영 데이터 기반 Variable Calibration
2. Resource 투입 패턴 추가 수집
3. 실제 KPI와 Simulation 결과 비교 및 재검증

이 필요합니다.



## 💡 What I Learned
> 내가 데이터 분석가로서 특별히 배운 것을 보여주는 것으로 하자. 나는 분석을 하면서 무엇을 새롭게 알게 되었고, 그 때문에 무엇을 바꾸었는가? 관점으로 적어야 함.


**분석의 목표가 달라지면, 같은 데이터도 전혀 다르게 보였습니다.**
초기에는 "리드타임이 왜 긴가"를 설명하는 데 집중했지만, 프로젝트가 진행되면서 진짜 질문은 "어떻게 하면 실제로 줄일 수 있는가"로 바뀌었습니다. 

EDA와 가설 검정으로 병목과 원인을 확인하는 것만으로는 이 질문에 답할 수 없었고, 그래서 시뮬레이션으로 개입 효과를 직접 검증하는 방향으로 방법론 자체를 바꿔야 했습니다.

이번 프로젝트에서 가장 크게 달라진 점도 여기에 있습니다 — 데이터를 "설명"하는 것과 데이터로 "의사결정을 검증"하는 것은 전혀 다른 작업이라는 걸 체감한 것입니다.


**우선순위 스코어를 설계하면서, 데이터 리키지를 스스로 걸러내는 기준을 세워야 했습니다.**
Business Value × Operational Risk로 우선순위를 매기는 과정에서, 초기에 정의한 변수 중 일부는 접수 시점에는 알 수 없는 정보(사후적으로만 확인 가능한 값)를 포함하고 있었습니다. 시뮬레이션이 실제 운영 의사결정을 흉내 내는 것이라면, 그 시점에 몰랐을 정보를 미리 아는 것처럼 쓰면 결과가 왜곡된다는 걸 뒤늦게 발견했고, 접수 시점 기준으로 계산 가능한 변수만 남기도록 다시 설계했습니다.
**배운 점:** 시뮬레이션·예측 모델에서는 "이 변수를 그 시점에 실제로 알 수 있었는가?"를 알아야 한다는 것입니다.

> 좋은 분석은 정답을 빨리 찾는 것이 아니라, 그 정답이 어떤 가정 위에 서 있는지를 끝까지 의심하는 과정이라고 생각합니다.
> 의사결정에 맞는 모델을 고르는 것이지, 모델에 맞춰 의사결정을 끼워 맞추는 것이 아니라는 것도 이번 프로젝트에서 다시 확인한 원칙입니다.






▼ 참고
이 질문을 먼저 두고 다시 분석하다 보니, 병목을 찾는 것만으로는 충분하지 않았습니다.
```Inform Client Survey → Survey```가 가장 긴 대기 구간이라는 사실을 확인한 뒤에도 "그렇다면 이 구간의 처리시간만 줄이면 되는가?"라는 질문이 남았습니다.
그래서 담당자별 Workload와 Resource Sharing 구조를 추가로 살펴보았고, 초기 Simulation이 실제 데이터의 대기 구조를 충분히 설명하지 못한다는 점을 확인하면서 모델 자체를 다시 설계했습니다.

결국 이번 프로젝트에서 제가 가장 많이 한 일은 분석을 추가하는 것이 아니라, 이전 분석에서 설명되지 않는 부분을 찾아 다시 질문하는 것이었습니다.


#### 시행착오 기록
① 단순 Queue 모델로는 실제 대기 구조를 설명할 수 없었습니다.

초기에는 Survey 구간의 처리시간과 Queue만을 중심으로 Simulation을 구성했습니다.

하지만 실제 데이터의 대기시간과 Simulation 결과 사이에 차이가 발생했습니다.

이를 단순한 파라미터 조정 문제로 보지 않고 “실제 운영에서 Queue를 만드는 Resource가 무엇인가?”라는 질문으로 다시 접근했습니다.

담당자별 Survey 외 업무 수행량을 추가로 분석한 결과, 일부 담당자가 Survey와 다른 수리 업무를 동시에 수행하는 구조를 확인했고, 최종 모델에는 이를 Resource Sharing 구조로 반영했습니다.

> 그래서 이 분석이 의사결정에 어떤 답을 줄 수 있고, 무슨 문제를 어떻게 해결할 수 있는가? “이 조직이 해결하려는 문제는 무엇이고, 그 문제를 해결하기 위해 어떤 답이 필요한가?”

“무엇을 분석할까?”보다 “무엇을 증명해야 할까?”를 먼저 생각하게 되었습니다.

병목을 찾는 것 자체가 목적이라면 Inform Client Survey → Survey의 대기시간이 길다는 사실만으로도 분석은 끝날 수 있었습니다.

하지만 실제 의사결정을 지원하려면 다음 질문까지 답해야 했습니다.

이 병목은 왜 발생하는가?
무엇을 바꾸면 실제로 개선되는가?
개선안 중 어떤 선택이 가장 효과적인가?
그 효과는 어떤 가정 위에 있는가?
실제 운영에 적용한다면 무엇을 추가로 측정해야 하는가?

그래서 이번 프로젝트에서는 현상 진단 → 원인 검증 → 개선안 설계 → Simulation → 한계 및 추가 검증 설계까지 분석 범위를 확장했습니다.