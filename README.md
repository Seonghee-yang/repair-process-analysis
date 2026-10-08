
# 이벤트 로그 기반 수리 서비스 리드타임 분석 및 개선 시뮬레이션
> "리드타임을 줄이려면, 어디를 바꿔야 하는가?"
수리 프로세스 이벤트 로그를 기반으로 리드타임을 늘리는 병목을 규명하고, 어떤 자원 배분 정책이 효과적인지 시뮬레이션으로 검증한 프로젝트입니다.

📄 분석 과정 전체(시각화 포함)는 포트폴리오 PDF 에 정리되어 있습니다. 이 문서는 프로젝트 요약이며, 코드와 설계 과정은 notebooks/에서 확인하실 수 있습니다.


## 🎯 Analysis Objective
> **"리드타임을 단축하면서 제한된 운영 자원을 어디에, 어떤 기준으로 배분해야 하는가?"**

특정 공정의 작업시간만 줄이는 것이 아니라,
- 전체 리드타임
- 핵심 병목 구간
- 비즈니스 영향이 큰 Case
- 담당자별 Resource 편차

를 함께 고려하여 실제 운영 정책임을 가정한 개선안을 검증했습니다.

## 🔑 Key Findings
> **병목의 핵심은 수리 작업 자체의 처리 속도보다, 작업과 작업 사이에서 Case가 정체되는 Queue 구조**

**1. 리드타임은 대기 시간에서 발생했으며, 병목은 특정 구간에 집중되어 있습니다.**

전체 리드타임의 92.8%가 공정 간 대기 시간에서 발생했으며, ```Inform Client Survey → Survey``` 구간이 평균 **3.2일(76.8시간)**로 가장 큰 병목입니다. 

→ 작업 속도 개선보다 Queue 구조 자체를 줄이는 것이 우선 과제였습니다.

**2. 재수리는 케이스당 지연 폭은 크지만, 전체 병목의 원인은 아닙니다.**

```Intern → Intern``` 재수리 시퀀스는 케이스당 평균 1.36일의 추가 지연을 유발하지만, 실제 발생 빈도는 12.7%(127건)에 그칩니다. 

→ 전체 프로세스 재설계보다 해당 케이스만 타겟팅하는 것이 더 효율적입니다.

**3. 현재 Queue에는 비즈니스 영향도를 반영하지 못하고 있습니다.**

현재 서비스 우선순위와 고장 심각도는 실제 처리 순서에 반영되지 않았습니다. 반면, 상위 20%의 고영향 Case가 전체 영향의 48.3%를 차지해, 영향도에 따른 우선순위 관리가 필요했습니다.

→ 영향도 기반의 Priority Score가 필요하다는 근거가 되었습니다.

**4. 내부 수리는 외주보다 SLA 실패 위험이 두 배 정도 높았습니다.**

내부 수리 SLA 실패율은 27.8%로 외주(14.4%)의 약 2배 차이를 보였으며, 이 차이는 통계적으로 유의합니다(카이제곱, p=0.0316). 

→ 내부 수리 프로세스의 개선을 우선 과제로 설정하였습니다.

## 📌 Project Overview
1,000건의 수리 케이스에서 발생한 이벤트 로그를 기반으로 **왜 리드타임이 증가하는가?** 를 분석하고, 분석 결과를 실제 운영 정책으로 연결하기 위해 **"무엇을 바꾸면 리드타임을 줄일 수 있는가?"** 까지 검증했습니다.

- 프로세스 분석을 통해 **"공정 간 Waiting Time이 리드타임을 지배"** 하고 있음을 확인
- ```Inform Client Survey → Survey``` 병목을 중심으로 원인을 분석
- **우선순위 스케줄링 → 병목 Capacity → 담당자 Resource 재배분** 순으로 시뮬레이션 검증


## 🚨 Problem
- **과도한 리드타임 지연**

  고객 접수부터 서비스 완료까지 일부 케이스에서 리드타임이 과도하게 증가하는 현상 발생

- **원인 규명 지표 부재**
  - 이벤트 로그만으로는 "무엇이 일어났는지"는 알 수 있어도 "왜 지연되는지"는 설명하기 어려웠습니다.
  - 지연 원인이 특정 공정 문제인지, 운영 프로세스 구조 전반의 문제인지 데이터 기반 검증 필요했습니다.

- **비즈니스 리스크 증대**

  서비스가 지연될 경우, 소수의 고가치 Case에 리스크가 집중될 가능성이 있었습니다.

#### 📋 Project Information
| 항목 | 내용 |
|---|---|
| 기간 | 2026.05 ~ 2026.06 |
| 역할 | 개인 프로젝트 |
| 주요 업무 | 데이터 전처리 · 통계 가설 검증 · 시각화 · 시뮬레이션 설계 |
| Tools | Python · MySQL · Tableau · SimPy |


#### 📂 Dataset
- 1,000건의 수리 프로세스 이벤트 로그를 활용했습니다.
- ```CaseID```를 기준으로 하나의 수리 요청에 여러 Task 이벤트가 연결되는 구조입니다.

| 컬럼명 | 설명 |
| :--- | :--- |
| caseID | 수리 요청 건별 고유 식별자 |
| taskID | 세부 공정 단계 (ex : Inform Client Survey, Survey, InternRepair) |
| originator | 해당 공정을 수행한 담당자 |
| eventtype | 작업 이벤트 유형(Start / Complete) |
| timestamp | 이벤트 발생 시각 |
| contact | 접수 수단|
| RepairType | 수리 유형 |
| RepairInternally | 자사 수리 가능 여부 |
| EstimatedRepairTime | 접수 시점 예상 수리 시간(분) |
| RepairCode | 수리코드 |
| RepairOK | 수리 종료 여부 |


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
- `True Waiting Time` 등 핵심 파생 변수 생성
- 도메인 기반 프록시 변수 설계
- 4가지 가설 통계 검증
- Case 별 비용 집중도 분석

#### 4. Simulation
- 우선순위 스케줄링 × 병목 Capacity × 담당자 Resource 재배분을 결합한 5가지 시나리오(A~E)를 SimPy 기반으로 비교


## ⚙️ Feature Engineering

#### 주요 파생변수
| 변수명 | 정의 및 목적 |
| --- | --- |
| `True Waiting Time` | 순수 작업시간을 제외한 실질 대기시간 |
| `Handover Type` | 공정 이관 유형 분류 |
|` Repair Type` | 내부/외부 수리 유형 구분 |
| `Repair Mode` | 단일/다중 수리 유형 구분 |
| `Locked Capital` | 지연으로 인해 공정에 묶여 있는 자본 규모 |


#### 도메인 기반 가상 변수
| 변수명 | 정의 및 목적 |
| --- | --- |
| ```product_category``` | 제품군별(대형가전, IT 가전 등) 지연 패턴 차이 분석을 위한 범주 |
| ```product_price``` | 제품 가격 |
| ```priority``` | 비즈니스 영향 및 운영 리스크 기반 우선순위(High / Medium / Low) |
| ```failure_severity``` | 접수 시점에 알 수 있는 정보만으로 산정한 고장 심각도(High / Medium / Low) |
| ```repair_cost``` | 수리 비용 |
| ```SLA_breach``` | 약정 서비스 수준 계약 위반 여부(시뮬레이션 결과 평가용 지표로만 사용) |

> 💡 Core Insight : 본 프로젝트에서는 원본 이벤트 로그만으로 확인하기 어려운 운영 특성을 보완하기 위해 도메인 가정 기반 Proxy 변수를 설계했습니다. 단, 해당 변수와 시뮬레이션 결과는 실제 운영 실측값이 아니며, 실제 적용을 위해서는 현업 데이터 기반의 추가 검증이 필요합니다.


## 🧪 Hypothesis Testing
#### Hypothesis 1. 재수리 발생은 Schedule Compliance 실패와 관련이 있는가?
> 재수리 Case에서 Schedule Compliance 저하가 확인되지만, 전체 대기시간의 핵심 원인은 아니었습니다.
- 재수리 발생 비중은 12.7%로 낮아 전체 Lead Time에 미치는 영향은 제한적
- → 국소적 개선 과제로 분류

#### Hypothesis 2. 제품 특성이 Lead Time에 영향을 미치는가?
> 제품 가격과 Lead Time 간 유의한 관계를 확인하지 못했습니다.

- OLS 회귀분석 p = 0.667
- → 제품 특성보다 공통 프로세스의 Waiting 구조가 핵심 지연 요인으로 판단

#### Hypothesis 3. 외부 위탁 수리는 내부 수리 대비 SLA 실패의 핵심 요인인가?
> 외주보다 내부 수리의 SLA 리스크가 높았습니다.
- 외주 SLA 실패율: `14.4%`
- 내부 SLA 실패율: `27.8%`
- Chi-square test: `p = 0.0316`
- → 외주 축소보다 **내부 수리 공정의 SLA 관리 개선을 우선**

#### Hypothesis 4. 우선순위와 고장심각도가 실제 운영에 활용되고 있는가?
> Priority·Severity 모두 현재 Queue Scheduling에 반영되지 않았습니다.
- Priority별 SLA / Waiting Time 차이가 크지 않음
- Severity별 대기시간 분포도 유사
- 고위험 Case를 별도로 우선 처리하는 구조 부족
- → 접수 시점 정보를 활용한 **Dynamic Priority Score 설계**


## 📈 Simulation & Impact
Event Log는 이미 발생한 운영 결과를 보여주기 때문에, **정책 변경 이후의 결과를 직접 관찰할 수 없습니다.**

따라서 SimPy 기반 Discrete Event Simulation을 구축하여 운영 정책별 효과를 비교했습니다.

### 3 Simulation Evolution

```text
Attempt 1
Priority Scheduling - 우선순위 스케줄링
        ↓
Attempt 2
Bottleneck Capacity - 병목 Capacity 확대
        ↓
Attempt 3
Integrated Resource Model - 담당자 업무 구조 반영 Resource 재배분
```

#### Attempt 1 — Priority Scheduling
> 처리 순서에 Priority를 적용

→ VIP 리드타임은 개선되었지만, 전체 리드타임 개선에는 한계가 있었습니다

#### Attempt 2 — Bottleneck Capacity
> Inform → Survey 구간의 Capacity를 확대

  - Survey 자격 보유 Resource: 11명
  - 관측된 동시 투입 수준: 약 3명
  - Capacity 3명 기준 가동률: 114%
  - Capacity 5명 기준 가동률: 약 68%

→ Capacity 확대만으로는 실측 Survey 대기 시간을 설명하지 못했습니다.

#### Attempt 3 — Integrated Resource Model
> 담당자가 Survey 외 다른 수리 업무도 동시에 수행한다는 점을 반영
- 자격 보유 인원 ≠ 실제 투입 가능한 Resource

→ 담당자의 겸직 여부와 업무량을 모델에 반영해 전체 병목과 담당자 간 편차를 함께 개선하도록 Resource 배분 구조를 설계했습니다.



## 🏆 Scenario E — Integrated Resource Model
 단계적으로 검증한 결과, 담당자의 실제 업무 구조까지 반영한 **Scenario E**에서 가장 큰 개선 효과를 확인했습니다.

| 지표 | 개선 전 | 개선 후 (Scenario E) | 변화 |
|----------|----------|-----------| -- |
| 전체 리드타임 | 70.6h | 37.2h | **▼47.3%** |
| 핵심 병목(Inform → Survey) | 41.52h | 8.10h | **▼80.5%** |
| VIP 리드타임 | 67.05h | 43.00h | **▼35.9%** |
| 공정 내 동결 자본 | 8.09억 원 | 4.57억 원 | **▼3.52억 원** |
| 담당자 간 대기시간 편차 | 35.47h | 10.99h | **▼69.0%** |

※ ⚠️ Scenario E는 실제 운영 결과가 아닌,
Event Log와 설정한 운영 가정을 기반으로 한 Simulation 결과입니다.

#### 🎯 Priority Score

$$\text{Priority Score} = \text{MinMax (Business Value)} * \text{MinMax(Operational Risk)}$$

- **Business Value** : 수리 단가를 기준으로 산정한 접수 시점의 예상 수리비
- **Operational Risk** : 제품 카테고리를 기반으로 사전 추정한 고장 심각도

재수리 횟수, 외주 가산비 등 케이스 종료 후 확정되는 사후 정보는 제외하고, 접수 시점에 판단 가능한 정보만 사용했습니다.



## 📋 Recommendations
  **1. 데이터 기반 우선순위 스케줄링 도입**
  > ▶ 비즈니스 영향이 큰 Case의 대기 리스크를 관리

  접수 시점의 Business Value와 Operational Risk를 기반으로 Case별 Priority를 산정해 Queue에 반영합니다.
  

  **2. `Inform Client Survey → Survey` 공정 Capacity 확대**
  > ▶ 구조적 Queue 누적을 방지

  핵심 병목의 Queue와 담당 Resource를 모니터링하고, 피크 상황에서 자격 보유 인력을 유연하게 배치합니다.
  
  **3. 담당자 업무량 기반 Resource 재배분**
  > ▶ 담당자 간 대기시간 편차 완화

  담당자의 겸직 여부와 현재 업무량을 고려해 특정 담당자에게 업무가 집중되지 않도록 Resource를 재배분합니다.

  **4. 국소 병목(재수리·외주 공정) 운영 가이드라인 정립**
  - 재수리 및 외주 공정은 개별 Case의 SLA 및 지연 리스크를 줄이기 위한 SOP와 모니터링 기준을 마련합니다. 
  - 재수리·외주 지연 50% 단축 가정 시 전체 리드타임 최대 ▼0.66h 개선 효과가 있습니다.



## 📊 Tableau Dashboard
🔗 **[Tableau Public Dashboard]("https://public.tableau.com/app/profile/.55641854/vizzes")**

####  Dash1 - 현황 진단
전체 프로세스 및 리드타임 구조

#### Dash2 - 병목 구간 분석
Waiting Time 및 담당자 전환 분석

#### Dash3 - 시뮬레이션 결과
시나리오 E 개선 효과


## 📁 Repository Structure

```
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
│
└── outputs/
    ├── process_flow.png
    ├── lead_time_distribution.png
    ├── bottleneck_analysis.png
    ├── hypothesis_results.png
    └── simulation_results.png
```
## 💡 What I Learned
처음에는 **"리드타임이 왜 긴가?"**를 설명하는 데 집중하여 가장 큰 병목 구간을 찾는 것에 초점을 맞췄습니다.

하지만 병목과 원인을 확인하고 나니

**"그렇다면 무엇을 바꾸면 실제로 리드타임을 줄일 수 있는가?"**

라는 새로운 질문이 생겼습니다.

이벤트 로그를 분석해보니 `Inform Client Survey → Survey` 구간의 대기시간이 가장 길었고, 처음에는 이 구간의 Capacity를 늘리면 문제가 해결될 거라고 생각했습니다.

그런데 실제 데이터를 기준으로 시뮬레이션해보니 생각만큼 설명되지 않았습니다.

그래서 담당자별 업무량과 다른 업무를 함께 수행하는 구조를 다시 살펴봤고, 자격을 가진 사람이 많다고 해서 실제로 그 업무에 투입할 수 있는 사람이 많은 것은 아니라는 점을 확인했습니다.

이후 담당자의 업무 구조까지 반영해 Resource를 다시 구성하고, `Priority Scheduling → Bottleneck Capacity → Resource 재배분` 순으로 시뮬레이션을 확장했습니다.

이 과정을 거치면서 분석 결과가 예상과 다를 때 결과를 맞추려고 하기보다, 무엇을 놓쳤는지 다시 보는 것이 중요하다는 것을 배웠습니다.

Priority Score도 같은 방식으로 다시 점검했습니다. 처음에는 여러 변수를 활용하려 했지만, 실제 운영에서 사용하려면 **"이 정보를 접수 시점에 알 수 있는가?"** 를 먼저 생각했습니다. 따라서 이번 분석에서는 접수 시점에 확인할 수 있는 정보와 도메인 기반 추정값으로 Score를 설계했습니다.


이번 프로젝트를 통해 데이터를 바탕으로 여러 개선안을 만들고, 그 효과를 검증하면서 부족한 부분을 다시 찾고 보완하는 과정을 경험했습니다. 이를 통해 앞으로는 분석 결과를 보여주는 데 그치지 않고, “그래서 무엇을 바꿀 것인가?”까지 답할 수 있는 분석을 해야 한다는 것을 배웠습니다.




## ⚠️ Limitations / 향후 발전
- `product_price`, `priority`, `failure_severity` 등 Proxy 변수는 실제 운영 데이터가 아닌 도메인 리서치 기반 가정값입니다.
- 시뮬레이션을 통해 개선 효과를 사전 검증했지만, 실제 운영에서 정책을 적용한 사후 검증이나 A/B Test는 수행하지 못했습니다.
- Scenario E의 개선 효과 역시 실제 운영 성과가 아닌 Event Log와 운영 가정을 기반으로 한 Simulation 결과입니다.

- 실제 적용을 위해서는
  1. 실제 운영 데이터 기반 Variable Calibration
  2. Resource 투입 패턴 추가 수집
  3. 실제 KPI와 Simulation 결과 비교 및 재검증

  이 필요합니다.

- 이번 프로젝트에서는 접수 시점에 확인할 수 있는 정보와 도메인 기반 추정값을 활용해 Priority Score를 설계했습니다. 다만 고장 심각도를 실제 데이터로 예측하는 모델까지 구축하지는 못했습니다. 이후 과거 수리 데이터를 활용해 접수 시점의 고장 심각도를 예측한다면, 이를 Operational Risk에 반영해 Priority Score를 더욱 정교하게 만들 수 있다고 생각했습니다.