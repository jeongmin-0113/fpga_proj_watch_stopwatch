# stopwatch_watch_박정민_방지윤_20260802

# stopwatch_watch

- **작성자**: 박정민 · 방지윤
- **작성일**: 2026-07-29
- **파일명**: stopwatch_watch_박정민_방지윤_20260729

> 💡 **한 줄 요약**
stopwatch 모듈 + watch 모듈을 하나의 top module에 통합해 FPGA에 올린 프로젝트.
10000진 카운터에서 만든 tick(100만 분주 clk, 10ms = 1/100초)을 기준 tick으로 사용한다.
> 

> 📌 **발표 진행 방식**
실습에서 다룬 범위와 무관하게 **전체 구현 내용의 구조를 먼저 설명**하고,
그 다음 **바텀업(리프 모듈 → 상위 모듈 → top)** 순서로 하나씩 설명한다.
**테스트벤치가 있는 모듈은 “모듈 설명 → 테스트로 검증”까지 한 흐름으로** 다룬다.
> 

---

## 목차

1. 개요
2. 전체 구조 (모듈 트리 · 신호 흐름 · 역할 분담)
3. 발표 구성 (20분 분담)
4. 세부 이론
5. 설계 — 바텀업 모듈별 (설명 + 테스트 검증)
6. FPGA 보드 동작
7. 트러블슈팅
8. 결과 및 분석

---

## 1. 개요

### top module 블럭도

![topmodule.png](topmodule.png)

### watch fsm 상태도

![image.png](image.png)

### stopwatch fsm 상태도

![image.png](image%201.png)

### 프로젝트 설명

- 두 명이 각자 역할을 맡아 **watch + stopwatch 기능**을 함께 구현하고 하나의 FPGA 보드에 올리는 팀 프로젝트.
- stopwatch(시간 측정) + watch(시계, 시간 조정) 두 모드를 하나의 top에서 `sw`로 전환하며, 추가기능(save/load, 조정 자리 점멸, 12/24시간제)까지 구현했다.

### 설계 목적

- 파라미터화된 카운터를 **재사용**해 msec→sec→min→hour 자리올림 체인을 구성.
- **datapath / control unit 분리** — 데이터 조작·저장은 datapath, 상태(state) 생성은 control unit이 전담.
- 하나의 top에서 스위치로 모드·표시 형식을 선택하도록 통합.

### 설계 방법 요약

1. 100MHz clk를 100만 분주 → 10ms tick.
2. `time_counter`를 진법만 바꿔(100/60/60/24) 인스턴스화 → 카운터 체인.
3. `fnd_controller`가 분주 + 8자리 시분할 + BCD 디코딩으로 FND 표시.
4. watch는 기존 카운터에 up/down 조정 + 조정 대상 자리 FSM 추가.
5. top에서 debounce된 버튼과 `sw`를 조합해 두 datapath를 병렬로 두고 mux 선택.
6. 추가기능: save/load(F/F 저장), 조정 자리 점멸, 12/24시간제 변환.

### 결과

- stopwatch·watch 두 모드 + 추가기능 3종 모두 시뮬레이션으로 동작 확인
- FPGA (Basys3) 보드에서 정상 동작 확인

---

## 2. 전체 구조 (모듈 트리 · 신호 흐름 · 역할 분담)

### 2-1. 최상위 블럭도

![topmodule.png](topmodule.png)

![image.png](image%202.png)

### 2-2. 모듈 계층 트리 (전체 구현 내용)

```
top_stopwatch  ── 최상위 (박정민: 통합)
│
├─ btn_debouncer ×4                (buttons: L / R / UP / DOWN)
│
├─ [STOPWATCH 경로]
│   ├─ control_unit                (STOP/RUN/CLEAR/MODE +SAVE/LOAD)   ← 박정민(save/load 확장)
│   └─ stopwatch_datapath                                             ← 박정민(save/load 확장)
│       ├─ tick_gen_100hz          (10ms tick)
│       └─ time_counter ×4         (100·60·60·24, +load)
│
├─ [WATCH 경로]
│   ├─ watch_control_unit          (START/HOUR/MIN/SEC FSM)            ← 방지윤
│   └─ watch_datapath                                                 ← 박정민
│       ├─ tick_gen_100hz          (재사용)
│       ├─ demux_1x3 ×2            (up/down → 선택 자리로 라우팅)
│       └─ watch_time_counter ×4   (up/down 조정, HOUR 초기값 12)
│
├─ 12/24시간제 변환 로직            (top 내 조합논리, sw[2])            ← 방지윤
│
└─ fnd_controller                  (표시부)
    ├─ clk_div(1kHz) · counter_8 · decoder_2x4 · bcd
    ├─ digit_splitter ×4 · mux_8x1 ×2 · mux_2x1
    ├─ comparator_dot              (DP 50ms 점멸)
    └─ state_decoder + indicator ×4 (조정 자리 점멸)                   ← 방지윤
```

### 2-3. 신호 흐름 (한눈에)

```
버튼 → [debounce] → (sw[1] 게이팅) ┬→ stopwatch: control_unit → stopwatch_datapath ┐
                                   └→ watch    : watch_control_unit → watch_datapath ┘
                                                                                     │
        sw[1] mux 로 시간데이터 선택 → (watch면 sw[2] 12/24 변환) → fnd_controller → FND
```

### 2-4. 역할 분담

| 담당 | 박정민 | 방지윤 |
| --- | --- | --- |
| watch | **watch datapath** (demux_1x3, watch_time_counter, 통합) | **watch control unit** (FSM) |
| 통합 | **watch를 top module에 통합** (sw[1] mux/게이팅) | — |
| 추가기능 | **stopwatch save / load** | **12↔︎24시간제 변환**, **조정 자리 점멸 indicator** |

### 2-5. 스위치 및 버튼 정의

| 스위치 | 0 | 1 |
| --- | --- | --- |
| sw[0] | 초:밀리초 | 시:분 |
| sw[1] | 스톱워치 | 워치 |
| sw[2] | 24시간제 | 12시간제 (워치일 때만) |

| 버튼 | stopwatch | watch |
| --- | --- | --- |
| btn_L | run/stop | 반시계방향 자리 변경 |
| btn_R | clear | 시계방향 자리 변경 |
| btn_UP | mode (up/down) | up |
| btn_DOWN | save/load | down |
| btn_C | reset | reset |

---

## 3. 발표 구성 (총 20분) - 여기는 ppt에 넣지 말것!

> 원칙: **각자 구현한 부분은 각자 발표**. 도입·마무리만 공동. 전체 구조 설명 후 바텀업으로 진행.
> 

| 순서 | 시간 | 발표자 | 내용 |
| --- | --- | --- | --- |
| 1. 도입·전체 구조 | 3분 | 공동 | 목적, 역할 분담, 최상위 블럭도, **모듈 트리 전체** |
| 2. 기반 리프 모듈 | 3분 | 공동 | tick_gen_100hz, time_counter (+각 테스트) |
| 3. FND 표시부 | 2분 | 공동 | fnd 하위 모듈 → fnd_controller |
| 4. WATCH datapath | 3분 | **박정민** | demux_1x3, watch_time_counter, watch_datapath (+테스트) |
| 5. WATCH control unit | 2.5분 | **방지윤** | FSM 상태도 (+테스트) |
| 6. save/load 추가기능 | 2.5분 | **박정민** | control_unit·time_counter·datapath 확장 (+테스트) |
| 7. 조정 자리 점멸 indicator | 1.5분 | **방지윤** | state_decoder + indicator |
| 8. 12/24시간제 | 1.5분 | **방지윤** | 표시 직전 변환 (top 통합 테스트) |
| 9. top 통합·보드 시연·결론 | 1.5분 | 공동 | top 통합, FPGA 영상, 트러블슈팅 |

> 각 모듈은 **① 블럭도(설계 전 손그림) → ② vivado RTL schematic → ③ 동작 개념 한 문장 → ④ 소스코드 → ⑤ 코드 설명 → ⑥ (테스트 있으면) 테스트벤치 + 검증 결과** 순서로 발표한다.
> 

---

## 4. 세부 이론

- **분주(tick 생성)**: 10ns 주기 clk를 100만 번 세면 10ms. 이 tick을 최하위 카운터 입력으로 사용.
- **파라미터 재사용**: `time_counter #(COUNT_NUM)`으로 상위에서 진법 주입 → 코드 변경 없이 100/60/60/24진 카운터.
- **Moore FSM**: `watch_control_unit`은 state register + next-state 조합논리. 출력(state)은 레지스터 값이라 버튼 누른 순간이 아니라 **다음 clk 상승엣지에 갱신**.
- **FND 시분할**: 1kHz로 자리 선택 counter를 돌려 8자리를 빠르게 번갈아 켜서 동시에 켜진 것처럼 보이게 함.
- **버튼 디바운스**: 채터링 제거를 위해 `btn_debouncer`를 거친 신호를 control unit에 전달.
- **12시간제 변환**: 내부는 0~23으로 세고, 표시 직전에 1323→111, 0→12로 변환.

---

## 5. 설계 — top 연결 구조 → STOPWATCH → WATCH

### 5-1. top module 연결 구조 (전체 뼈대)

- **동작 개념**: 버튼을 debounce한 뒤 `sw[1]`로 게이팅해 **stopwatch·watch 두 경로에 병렬 공급**하고, 두 경로의 시간 데이터를 `sw[1]` mux로 골라 (watch면 12/24 변환 후) `fnd_controller`로 보낸다.
- **블럭도/schematic**: > [이미지: top 통합 schematic]

#### top module 코드 (포트 · debounce · 게이팅 · mux)

```verilog
module top_stopwatch (
    input clk,
    input reset,
    input btn_L,  // runstop(s) / 자리변경(w) 
    input btn_R,  // clear(s) / 자리변경(w)
    input btn_UP,  // mode(s) / up(w)
    input btn_DOWN,  // option(s) / down(w)
    input  [2:0] sw,        // sw[0]: 0-초:밀리초/1-시:분 sw[1]: 0-stopwatch/1-watch, sw[2] : watch의 12시간제
    output [3:0] fnd_com,
    output [7:0] fnd_data,
    output led  // indicator
);
    
    // btn debounder OUTPUT SIGNAL
    wire w_btn_L, w_btn_R, w_btn_UP, w_btn_DOWN;

    // control unit -> datapath
    wire w_runstop, w_clear, w_mode, w_save, w_load;
    wire w_is_data_saved;

    // 값 저장 상태를 출력
    assign led = w_is_data_saved;

    wire [1:0] w_state;
    wire [1:0] w_fnd_state;

    // 결정된 시간 데이터
    wire [6:0] w_msec;
    wire [5:0] w_sec, w_min;
    wire [4:0] w_hour;

    // stopwatch의 시간 데이터
    wire [6:0] w_msec_stopwatch;
    wire [5:0] w_sec_stopwatch, w_min_stopwatch;
    wire [4:0] w_hour_stopwatch;

    // watch의 시간 데이터
    wire [6:0] w_msec_watch;
    wire [5:0] w_sec_watch, w_min_watch;
    wire [4:0] w_hour_watch;

    // watch의 12시간제
    wire w_format12_watch;
    reg [4:0] w_hour_display_watch;
    assign w_format12_watch = sw[2];

		// watch의 12/24시간제 시간 계산
    always @(*) begin
        w_hour_display_watch = w_hour_watch; //sw[2] = 0이면 원래 24시간제
        if (w_format12_watch) begin  //12시간제 스위치 키면
            if (w_hour_watch > 12)
                w_hour_display_watch = w_hour_watch - 12;  //13~23을 1~11로
            else if (w_hour_watch == 0)
                w_hour_display_watch = 12;  //00시를 12시로
        end
    end

		// sw[1] 입력에 따라 watch/stopwatch data source 결정
		assign w_msec = (sw[1]) ? w_msec_watch : w_msec_stopwatch;
    assign w_sec = (sw[1]) ? w_sec_watch : w_sec_stopwatch;
    assign w_min = (sw[1]) ? w_min_watch : w_min_stopwatch;

    // watch일 땐 12시간제, stopwatch는 w_hour_stopwatch로
    assign w_hour = (sw[1]) ? w_hour_display_watch : w_hour_stopwatch;

		// 각 자리수 변경시 깜빡임 위치 fnd에 연결 -> stopwatch일 때는 깜빡이지 않음
    assign w_fnd_state = (sw[1]) ? w_state : 2'b00;

    ...

    fnd_controller U_FND_CNTL (
        .clk(clk),
        .reset(reset),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour),
        .state(w_fnd_state),
        .sw(sw[1:0]),
        .display_mode(sw[0]),  // sw[0] -> 0=초/1=시간 선택
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );

endmodule
```

- **코드 설명**: 하나의 버튼 세트를 두 모드가 공유하도록 `& sw[1]` / `& !sw[1]`로 게이팅(각 소절에서). 시간 데이터는 폭이 다른 4묶음(msec/sec/min/hour)을 각각 mux.

#### 5-1-1. 공통 표시부 — fnd_controller (+ FND 리프 모듈)

- **동작 개념(소스 전)**: 1kHz 자리 순회(counter_8) + digit_splitter로 자릿수 분리 + mux로 자리 선택 + BCD 디코딩. `display_mode`(sw[0])로 초:밀리초 / 시:분 세트 선택.

FND 리프 모듈:

```verilog
module digit_splitter #(parameter BIT_WIDTH = 7) (
    input  [BIT_WIDTH-1:0] ds_in,
    output [3:0] digit_1,
    output [3:0] digit_10
);
    assign digit_1  = ds_in % 10;
    assign digit_10 = (ds_in / 10) % 10;
endmodule

module comparator_dot #(parameter MSEC_WIDTH = 7) (
    input [MSEC_WIDTH-1:0] msec,
    output dot_onoff
);
    // 0~49ms -> 0(켜짐, LED는 0이 켜짐) / 50~99ms -> 1(꺼짐)
    assign dot_onoff = (msec < 50);
endmodule

module mux_2x1 (
    input [3:0] in0, input [3:0] in1, input sel,
    output [3:0] mux_out
);
    assign mux_out = (sel) ? in1 : in0;
endmodule

module counter_8 (
    input clk, input reset,
    output [2:0] digit_sel
);
    reg [2:0] counter_reg;
    assign digit_sel = counter_reg;
    always @(posedge clk, posedge reset) begin
        if (reset) counter_reg <= 0;
        else       counter_reg <= counter_reg + 1;  // 0~7 순환
    end
endmodule
```

> `mux_8x1`, `clk_div`, `decoder_2x4`, `bcd`는 실습 모듈을 그대로 사용.
> 

fnd_controller (기본형):

```verilog
module fnd_controller #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input                   clk,
    input                   reset,
    input  [MSEC_WIDTH-1:0] msec,
    input  [ SEC_WIDTH-1:0] sec,
    input  [ MIN_WIDTH-1:0] min,
    input  [HOUR_WIDTH-1:0] hour,
    input [1:0] state,
    input [1:0] sw,
    input                   display_mode,  // sw[0] -> 0=초/1=시간 선택
    output [           3:0] fnd_com,
    output [           7:0] fnd_data
);
    wire [3:0] w_msec_1, w_msec_10, w_sec_1, w_sec_10, w_min_1, w_min_10, w_hour_1, w_hour_10;
    wire [3:0] bcd;
    wire [3:0] w_msec_sec, w_min_hour;
    wire [2:0] w_digit_sel;
    wire clk_reg;
    wire w_dot_onoff;
    wire [3:0] w_indi_msec_1, w_indi_msec_10, w_indi_sec_1, w_indi_sec_10, w_indi_min_1, w_indi_min_10, w_indi_hour_1, w_indi_hour_10;
    wire [3:0] w_state_out;
    wire indi_digit_1, indi_digit_10;

    state_decoder U_STATE_DC (
        .clk(clk),
        .reset(reset),
        .state(state),
        .state_out(w_state_out)
    );

    indicator U_INDICATOR_MSEC (
        .clk(clk),
        .reset(reset),
        .sw(sw),
        .comp(w_dot_onoff),
        .state(w_state_out[0]),
        .digit_1(w_msec_1),
        .digit_10(w_msec_10),
        .indi_digit_1(w_indi_msec_1),
        .indi_digit_10(w_indi_msec_10)
    );

    indicator U_INDICATOR_SEC (
        .clk(clk),
        .reset(reset),
        .sw(sw),
        .comp(w_dot_onoff),
        .state(w_state_out[1]),
        .digit_1(w_sec_1),
        .digit_10(w_sec_10),
        .indi_digit_1(w_indi_sec_1),
        .indi_digit_10(w_indi_sec_10)
    );

    indicator U_INDICATOR_MIN (
        .clk(clk),
        .reset(reset),
        .sw(sw),
        .comp(w_dot_onoff),
        .state(w_state_out[2]),
        .digit_1(w_min_1),
        .digit_10(w_min_10),
        .indi_digit_1(w_indi_min_1),
        .indi_digit_10(w_indi_min_10)
    );

    indicator U_INDICATOR_HOUR (
        .clk(clk),
        .reset(reset),
        .sw(sw),
        .comp(w_dot_onoff),
        .state(w_state_out[3]),
        .digit_1(w_hour_1),
        .digit_10(w_hour_10),
        .indi_digit_1(w_indi_hour_1),
        .indi_digit_10(w_indi_hour_10)
    );

    clk_div U_CLK_DIV (
        .clk(clk),
        .reset(reset),
        .o_1khz(clk_reg)
    );

    counter_8 U_COUNTER_8 (
        .clk(clk_reg),
        .reset(reset),
        .digit_sel(w_digit_sel)
    );

    decoder_2x4 U_DC (
        .sel(w_digit_sel[1:0]),
        .an_com(fnd_com)
    );

    comparator_dot #(MSEC_WIDTH) U_COMP_DOT (
        .msec(msec),
        .dot_onoff(w_dot_onoff)
    );

    // digit splitter
    digit_splitter #(
        .BIT_WIDTH(MSEC_WIDTH)
    ) U_DS_MSEC (
        .ds_in(msec),  // parameter로 변경
        .digit_1(w_msec_1),
        .digit_10(w_msec_10)
    );

    digit_splitter #(
        .BIT_WIDTH(SEC_WIDTH)
    ) U_DS_SEC (
        .ds_in(sec),  // parameter로 변경
        .digit_1(w_sec_1),
        .digit_10(w_sec_10)
    );

    // 8x1 mux - msec & sec display
    mux_8x1 U_MUX_SEC (
        .in0(w_indi_msec_1),
        .in1(w_indi_msec_10),
        .in2(w_indi_sec_1),
        .in3(w_indi_sec_10),
        .in4(4'hf),
        .in5(4'hf),
        .in6({3'b111, w_dot_onoff}),
        .in7(4'hf),
        .sel(w_digit_sel),
        .mux_out(w_msec_sec)
    );

    // digit splitter - min & hour
    digit_splitter #(
        .BIT_WIDTH(MIN_WIDTH)
    ) U_DS_MIN (
        .ds_in(min),  // parameter로 변경
        .digit_1(w_min_1),
        .digit_10(w_min_10)
    );

    digit_splitter #(
        .BIT_WIDTH(HOUR_WIDTH)
    ) U_DS_HOUR (
        .ds_in(hour),  // parameter로 변경
        .digit_1(w_hour_1),
        .digit_10(w_hour_10)
    );

    // mux 8x1 - min & hour display
    mux_8x1 U_MUX_HOUR (
        .in0(w_indi_min_1),  // sel 3'b000
        .in1(w_indi_min_10),  // sel 3'b001
        .in2(w_indi_hour_1),  // sel 3'b010
        .in3(w_indi_hour_10),  // sel 
        .in4(4'hf),
        .in5(4'hf),
        .in6({3'b111, w_dot_onoff}),
        .in7(4'hf),
        .sel(w_digit_sel),  // mux sel
        .mux_out(w_min_hour)
    );

    // 초:밀리초와 시:분 디스플레이 중 display 모드에 의해 선택된 데이터가 bcd로
    mux_2x1 U_MUX_2x1 (
        .in0(w_msec_sec),
        .in1(w_min_hour),
        .sel(display_mode),
        .mux_out(bcd)
    );

    bcd U_BCD (
        .bcd_in (bcd),
        .bcd_out(fnd_data)
    );

endmodule
```

- **코드 설명**: DP 자리(sel=6)는 comparator_dot로 50ms 점멸. 확인: msec≥50 → `7f`(DP만), 0~49 → `ff`(모두 꺼짐).
- watch의 **조정 자리 점멸(state_decoder + indicator)** 은 이 fnd_controller에 포트를 추가해 얹은 것 → 5-3-3에서 다룸.

### 5-2. STOPWATCH

![image.png](image%201.png)

- 6개의 상태를 가지는 stopwatch를 구현
    - stop: 초기 상태이며 다른 state로 이동 가능한 유일한 상태
    - run: stopwatch가 mode 값에 따라 up/down으로 작동하는 상태.
        - btn_L 입력 == i_runstop 입력으로 run/stop 상태 이동을 결정
    - mode: stopwatch가 어떻게 동작할지 결정하는 상태
        - btn_UP 입력 == i_mode 입력으로 up/down stopwatch 동작 토글
    - clear: 현재 stopwatch의 동작 값을 초기값으로 돌리는 상태
        - btn_R 입력 == i_clear 입력으로 값 clear
        - 단, save로 저장된 시간 데이터는 지우지 않음
    - save: 현재 stopwatch의 동작 값을 저장
        - btn_DOWN 입력 == i_save_load 입력으로 상태 결정
        - save된 데이터 없는 상태에서 i_save_load 시 현재 값 save함
    - load: 현재 stopwatch의 동작 값에 저장된 데이터 값을 덮어쓰기
        - btn_DOWN 입력 == i_save_load 입력으로 상태 결정
        - save된 데이터 존재할 때 i_save_load면 저장된 데이터를 load

#### 5-2-1. stopwatch control unit 모듈 설계 및 테스트벤치

#### tick_gen_100hz — 10ms tick 생성 *(테스트 有)*

- **동작 개념(소스 전)**: 100MHz clk를 100만 번 세면 10ms → 그때 1클럭짜리 tick 1개. (watch도 이 모듈을 그대로 재사용)
- **schematic**

![image.png](image%203.png)

```verilog
module tick_gen_100hz (
    input clk,
    input reset,
    output reg o_tick
);
    parameter F_COUNT = 1_000_000;
    reg [$clog2(F_COUNT)-1:0] counter_reg;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_reg <= 0;
            o_tick <= 1'b0;
        end else begin
            if (counter_reg == 1_000_000 - 1) begin
                counter_reg <= 0;
                o_tick <= 1'b1;
            end else begin
                counter_reg <= counter_reg + 1;
                o_tick <= 1'b0;
            end
        end
    end
endmodule
```

- **코드 설명**: 99만 9999번 clk가 지난 뒤 다음 posedge에서 counter 0 초기화 + tick 발생.

**✔ 테스트 검증**

```verilog
module tb_tick_gen_100hz ();
    reg clk, reset;
    wire o_tick;
    tick_gen_100hz dut (.clk(clk), .reset(reset), .o_tick(o_tick));
    always #5 clk = ~clk;
    initial begin
        clk = 0; reset = 1; #10; reset = 0;
        #(1_000_000 * 10 * 2);
        $stop;
    end
endmodule
```

![image.png](image%204.png)

- 99만 9999 clk 후 다음 posedge에서 0으로 초기화되며 o_tick 1펄스 발생 확인.
- 10ms + 5ns 지나야 1 tick인 이유

![image.png](image%205.png)

- 첫 clk posedge가 5ns에 존재

#### control_unit — stopwatch FSM (+ save/load 상태) — 박정민

![image.png](image%201.png)

- **동작 개념**
    - STOP/RUN/CLEAR/MODE 기본 4상태에 SAVE/LOAD 추가
    - STOP에서 down 시 **저장 데이터 유무로 SAVE/LOAD 분기**
    - 데이터 조작은 datapath가 하고 여기서는 state만 생성.

```verilog
module control_unit (
    input  clk,
    input  reset,
    input  i_runstop,
    input  i_clear,
    input  i_mode,
    input  i_save_load, // btn down
    input i_is_data_saved, // datapath에 데이터 저장되어 있는지 t/f 
    output o_runstop,
    output o_clear,
    output o_mode,
    output o_save, // data save trigger signal
    output o_load  // data load trigger signal

);
    parameter STOP = 3'b000, RUN = 3'b001, CLEAR = 3'b010, MODE = 3'b011, SAVE = 3'b100, LOAD = 3'b101;

    reg [2:0] c_state, n_state;

    // output -> feedback 구조로 구현 

    //current state
    reg run_stop_reg, clear_reg, mode_reg, save_reg, load_reg;
    // next는 next
    reg run_stop_next, clear_next, mode_next, save_next, load_next;

    assign o_runstop = run_stop_reg;
    assign o_clear = clear_reg;
    assign o_mode = mode_reg;
    assign o_save = save_reg;
    assign o_load = load_reg;

    //state + output register
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            c_state <= STOP;
            run_stop_reg <= 1'b0;
            clear_reg <= 1'b0;
            mode_reg <= 1'b0;
            save_reg <= 1'b0;
            load_reg <= 1'b0;
        end else begin
            c_state <= n_state;
            run_stop_reg <= run_stop_next;
            clear_reg <= clear_next;
            mode_reg <= mode_next;
            save_reg <= save_next;
            load_reg <= load_next;
        end
    end

    //next state + next output CL
    always @(*) begin
        n_state = c_state;
        run_stop_next = run_stop_reg;
        clear_next = clear_reg;
        mode_next = mode_reg;
        save_next = save_reg;
        load_next = load_reg;
        case (c_state)
            STOP: begin
                //moore output
                run_stop_next = 1'b0;
                clear_next = 1'b0;
                load_next = 1'b0;
                save_next = 1'b0;
                if (i_runstop) n_state = RUN;
                else if (i_clear) n_state = CLEAR;
                else if (i_mode) n_state = MODE;
                else if (i_save_load & !i_is_data_saved) n_state = SAVE;
                else if (i_save_load & i_is_data_saved) n_state = LOAD;
                else n_state = c_state;
            end
            RUN: begin
                run_stop_next = 1'b1;
                if (i_runstop) begin
                    n_state = STOP;
                end
            end
            CLEAR: begin
                clear_next = 1'b1;
                n_state = STOP;
            end
            MODE: begin
                mode_next = ~mode_reg;
                n_state   = STOP;
            end
            SAVE: begin
                save_next = 1'b1;
                n_state   = STOP;
            end
            LOAD: begin
                load_next = 1'b1;
                n_state   = STOP;
            end
        endcase
    end

endmodule
```

- 테스트벤치

```verilog
module tb_stopwatch_control_unit();
    parameter TICK_DELAY = 1_000_000 * 10;

    reg clk, reset;
    reg btn_L, btn_R, btn_UP, btn_DOWN;
    reg  [2:0] sw;

    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire [1:0] led;

    top_stopwatch dut (
        .clk(clk),
        .reset(reset),
        .btn_L(btn_L),  // runstop(s) / 자리변경(w) 
        .btn_R(btn_R),  // clear(s) / 자리변경(w)
        .btn_UP(btn_UP),  // mode(s) / up(w)
        .btn_DOWN(btn_DOWN),  // option(s) / down(w)
        .sw(sw),  // sw[0]: 0-stopwatch / 1:watch
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .led(led)  // indicator
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        btn_L = 0;
        btn_R = 0;
        btn_UP = 0;
        btn_DOWN = 0;
        sw = 3'b000;
        #10;
        reset = 0;
        
        #(TICK_DELAY*5);

        btn_L = 1; //run
        #(TICK_DELAY*5);

        btn_L = 0; //stop
        #(TICK_DELAY*5);

        btn_DOWN = 1; //save
        #(TICK_DELAY*5);

        btn_R = 1; //clear
        #(TICK_DELAY*5);

        btn_DOWN = 1; //load
        #(TICK_DELAY*5);

        btn_UP = 1; //mode
        #(TICK_DELAY*5);

        btn_L = 1; //start
        #(TICK_DELAY*5);

        btn_UP = 1; //run 중 mode - 무시됨
        #(TICK_DELAY*5);

        btn_DOWN = 1; //run 중 save - 무시됨
        #(TICK_DELAY*5);

        $stop;
    end

endmodule
```

- 유효 루트 1 (stop→run)

![image.png](image%206.png)

- button debouncer의 q reg가 ff가 되는 순간 1clk 동안 debounce 신호 생성
- debounce 된 신호가 온 다음 clk posedge에 o_runstop을 1로 설정
- i_runstop = 1 이 온 후 바로 next state 000(stop) → 001(run) 으로 변경.
- 다음 clk posedge에 c_state에 n_state 반영
- 다음 clk posedge에 출력 (o_runstop)에 c_state 반영

![image.png](image%207.png)

- stop(000) → mode(011) 도 i_mode (버튼 up debouncer 입력) 들어오면 n_state 반영
- 다음 clk posedge에 c_state에 n_state 반영
- 다음 clk posedge에 output (o_mode)에 c_state 반영 (o_mode가 토글됨)

- 유효하지 않은 동작

![image.png](image%208.png)

- run 중인 상태에서 btn_DOWN 입력 들어와 i_save_load 1 됨
- run(001)에서 save(100) 혹은 load(101)로 가는 루트가 fsm에 존재하지 않음
- 따라서 입력이 상태에 반영되지 않음

#### 5-2-2. stopwatch datapath 모듈 설계 및 테스트벤치

time_counter + load 추가

- **동작 개념**
    - mode == 0이면 up counter / 1이면 down counter로 동작
    - i_tick이 왔을 때 run_stop 신호가 1이면 count
    - load == 1이 되면 time_cnt를 value (저장되어있는 시간 값)으로 덮어쓰기

time_counter에 load 추가:

```verilog
module time_counter #(parameter COUNT_NUM = 100) (
    input clk, input reset, input i_tick,
    input mode, input run_stop, input clear,
    input load,                                  // load=1이면
    input [$clog2(COUNT_NUM)-1:0] value,         // value로 time_cnt 업데이트
    output reg [$clog2(COUNT_NUM)-1:0] time_cnt,
    output reg o_tick
);
    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            time_cnt <= 0; o_tick <= 1'b0;
        end else begin
            if (i_tick & run_stop) begin
                if (!mode) begin
                    time_cnt <= time_cnt + 1;
                    if (time_cnt == COUNT_NUM - 1) begin time_cnt <= 0; o_tick <= 1'b1; end
                end else begin
                    time_cnt <= time_cnt - 1;
                    if (time_cnt == 0) begin time_cnt <= COUNT_NUM - 1; o_tick <= 1'b1; end
                end
            end else begin
                o_tick <= 1'b0;
            end
            if (load) time_cnt <= value;         // load 시 value로 덮어씀
        end
    end
endmodule
```

#### datapath(F/F) *(테스트 有)*

![0F21C111-8793-46B2-930E-C0895C4AE76C.jpeg](0F21C111-8793-46B2-930E-C0895C4AE76C.jpeg)

- **동작 개념**
    - F/F에 현재 시간을 저장(save), 저장값을 카운터에 되돌림(load).
    - 저장 여부를 `o_is_data_saved`로 control unit에 연결 → save/load state 지정에 사용

datapath에 F/F 추가:

```verilog
module stopwatch_datapath #(
    parameter MSEC_WIDTH = 7,
    SEC_WIDTH = 6,
    MIN_WIDTH = 6,
    HOUR_WIDTH = 5
) (
    input                   clk,
    input                   reset,
    input                   runstop,
    input                   clear,
    input                   mode,
    input                   save,
    input                   load,
    output reg                 o_is_data_saved,
    output [MSEC_WIDTH-1:0] m_sec,
    output [ SEC_WIDTH-1:0] sec,
    output [ MIN_WIDTH-1:0] min,
    output [HOUR_WIDTH-1:0] hour
);

    wire w_tick_msec, w_tick_sec, w_tick_min, w_tick_hour;

    // f/f에 저장된 시간 데이터
    reg [MSEC_WIDTH-1:0] w_saved_msec;
    reg [ SEC_WIDTH-1:0] w_saved_sec;
    reg [ MIN_WIDTH-1:0] w_saved_min;
    reg [HOUR_WIDTH-1:0] w_saved_hour;

		// save/load 신호 왔을 때 시간 데이터 저장 및 control unit에 보낼 저장 상태 업데이트
		// reset으로는 데이터가 초기화되지만 clear로는 stopwatch 값만 초기화 (저장 데이터는 사라지지 않음)
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            w_saved_msec <= 0;
            w_saved_sec  <= 0;
            w_saved_min  <= 0;
            w_saved_hour <= 0;
            o_is_data_saved <= 0;
        end else begin
            if (save) begin
                w_saved_msec <= m_sec;
                w_saved_sec  <= sec;
                w_saved_min  <= min;
                w_saved_hour <= hour;
                o_is_data_saved <= 1;
            end
            if (load) begin
                o_is_data_saved <= 0;
            end
        end
    end

    tick_gen_100hz GEN_100HZ (
        .clk(clk),
        .reset(reset),
        .o_tick(w_tick_msec)
    );

    time_counter #(
        .COUNT_NUM(100)
    ) U_COUNTER_MSEC (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_msec),
        .mode(mode),
        .run_stop(runstop),
        .clear(clear),
        .load(load),
        .value(w_saved_msec),
        .time_cnt(m_sec),
        .o_tick(w_tick_sec)
    );

    time_counter #(
        .COUNT_NUM(60)
    ) U_COUNTER_SEC (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_sec),
        .mode(mode),
        .run_stop(runstop),
        .clear(clear),
        .load(load),
        .value(w_saved_sec),
        .time_cnt(sec),
        .o_tick(w_tick_min)
    );

    time_counter #(
        .COUNT_NUM(60)
    ) U_COUNTER_MIN (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_min),
        .mode(mode),
        .run_stop(runstop),
        .clear(clear),
        .load(load),
        .value(w_saved_min),
        .time_cnt(min),
        .o_tick(w_tick_hour)
    );

    time_counter #(
        .COUNT_NUM(24)
    ) U_COUNTER_HOUR (
        .clk(clk),
        .reset(reset),
        .i_tick(w_tick_hour),
        .mode(mode),
        .run_stop(runstop),
        .clear(clear),
        .load(load),
        .value(w_saved_hour),
        .time_cnt(hour),
        .o_tick()
    );

endmodule
```

- **코드 설명**: 기능(save)/유무(o_is_data_saved) 되먹임으로 down 버튼 시 SAVE/LOAD를 구분. 한 번 load된 데이터는 플래그가 0이 되어 다시 save 가능.

**✔ 테스트 검증**

```verilog
module tb_stopwatch_save_load ();

    parameter TICK_DELAY = 1_000_000 * 10;

    reg clk, reset;
    reg btn_L, btn_R, btn_UP, btn_DOWN;
    reg [2:0] sw;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire led;

    top_stopwatch dut (
        .clk(clk),
        .reset(reset),
        .btn_L(btn_L),  // runstop(s) / 자리변경(w) 
        .btn_R(btn_R),  // clear(s) / 자리변경(w)
        .btn_UP(btn_UP),  // mode(s) / up(w)
        .btn_DOWN(btn_DOWN),  // option(s) / down(w)
        .sw(sw),        // sw[0]: 0-초:밀리초/1-시:분 sw[1]: 0-stopwatch/1-watch, sw[2] : watch의 12시간제
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .led(led)  // indicator
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        btn_L = 0;
        btn_R = 0;
        btn_UP = 0;
        btn_DOWN = 0;
        sw = 3'b000;
        #10;
        reset = 0;

        #7;  // run
        btn_L = 1;
        #(TICK_DELAY * 5);
        #6;
        btn_L = 0;

        #(TICK_DELAY * 1_000_000);

        #6;  // stop
        btn_L = 1;
        #(TICK_DELAY * 5);
        btn_L = 0;

        #6;  // save
        btn_DOWN = 1;
        #(TICK_DELAY * 5);
        btn_DOWN = 0;

        #TICK_DELAY;

        #7;  // clear
        btn_R = 1;
        #(TICK_DELAY * 5);
        btn_R = 0;

        #(TICK_DELAY * 10);

        #6;  // load
        btn_DOWN = 1;
        #TICK_DELAY;
        btn_DOWN = 0;
        #(TICK_DELAY);

        #6;  // run
        btn_L = 1;
        #(TICK_DELAY * 10);
        btn_L = 0;
        $stop;

    end
endmodule
```

![image.png](image%209.png)

- save 타이밍: debounce된 down 버튼 입력의 downedge에 save 반영
- save 후 `is_data_saved` = 1 , led 점등
- saved msec, sec에 데이터 저장 확인

![image.png](image%2010.png)

- load 타이밍: debounce된 down 버튼 입력의 downedge에 load 반영
- load 후 is_data_saved = 0, led 꺼짐
- msec, sec가 저장된 값으로 업데이트됨 확인

#### 5-2-3. top 모듈에서 stopwatch 연결

- **연결 개념**
    - 버튼을 `& !sw[1]`로 게이팅(=stopwatch 모드일 때만 반응) → control_unit → stopwatch_datapath.
    - down 버튼은 save/load 트리거
    - save 여부는 `w_is_data_saved`로 control unit에 연결
    - 출력 시간은 `w_*_stopwatch`로 나가 top의 mux(5-1)로 들어간다.

```verilog
    // stopwatch control unit  (sw[1]=0 일 때만 버튼 반응)
    control_unit U_CNTL_UNIT (
        .clk(clk), .reset(reset),
        .i_runstop  (w_btn_L    & !sw[1]),
        .i_clear    (w_btn_R    & !sw[1]),
        .i_mode     (w_btn_UP   & !sw[1]),
        .i_save_load(w_btn_DOWN & !sw[1]),   // down = save/load
        .i_is_data_saved(w_is_data_saved),
        .o_runstop(w_runstop), .o_clear(w_clear), .o_mode(w_mode),
        .o_save(w_save), .o_load(w_load));

    // stopwatch datapath
    stopwatch_datapath U_DATAPATH (
        .clk(clk), .reset(reset),
        .runstop(w_runstop), .clear(w_clear), .mode(w_mode),
        .save(w_save), .load(w_load),
        .o_is_data_saved(w_is_data_saved),
        .m_sec(w_msec_stopwatch), .sec(w_sec_stopwatch),
        .min(w_min_stopwatch), .hour(w_hour_stopwatch));
```

- **코드 설명**
    - control unit은 state만 관리
    - datapath는 저장·복원을 담당
    
    ## stopwatch time counter
    
    ```jsx
    
    ```
    
    ![image.png](image%2011.png)
    
    ![image.png](image%2012.png)
    
    ![image.png](image%2013.png)
    

---

### 5-3. WATCH

#### 5-3-1. watch control unit 모듈 설계 및 테스트벤치

#### (a) watch_control_unit — 조정 대상 자리 FSM (방지윤) *(테스트 有)*

![image.png](image.png)

| state | 값 | 의미 |
| --- | --- | --- |
| START | 00 | 초기(조정 안 함) |
| HOUR | 01 | 시 설정 |
| MIN | 10 | 분 설정 |
| SEC | 11 | 초 설정 |
- **동작 개념(소스 전)**: btn_R(정방향)/btn_L(역방향)으로 START→HOUR→MIN→SEC 순환. 어느 자리를 조정할지 고르는 4상태 Moore FSM.

```verilog
module watch_control_unit (
    input clk, input reset,
    input btn_L, input btn_R,
    output [1:0] state
);
    parameter START = 2'b00;
    parameter HOUR  = 2'b01;
    parameter MIN   = 2'b10;
    parameter SEC   = 2'b11;

    reg [1:0] current_state, next_state;
    assign state = current_state;

    //state register
    always @(posedge clk, posedge reset) begin
        if (reset) current_state <= START;
        else       current_state <= next_state;
    end

    //next combination logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            START: if (btn_R) next_state = HOUR;  else if (btn_L) next_state = SEC;
            HOUR:  if (btn_R) next_state = MIN;   else if (btn_L) next_state = START;
            MIN:   if (btn_R) next_state = SEC;   else if (btn_L) next_state = HOUR;
            SEC:   if (btn_R) next_state = START; else if (btn_L) next_state = MIN;
        endcase
    end
endmodule
```

- **코드 설명**: state는 조합이 아니라 레지스터 값이라 버튼 누른 순간이 아니라 **다음 clk posedge에 갱신**.

**✔ 테스트 검증**

```verilog
`timescale 1ns / 1ps
module tb_watch_and_stopwatch_top ();
    parameter TICK_DELAY = 1_000_000 * 10;

    reg clk, reset;
    reg btn_L, btn_R, btn_UP, btn_DOWN;
    reg  [2:0] sw;

    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire  led;

    top_stopwatch dut (
        .clk(clk),
        .reset(reset),
        .btn_L(btn_L),  // runstop(s) / 자리변경(w) 
        .btn_R(btn_R),  // clear(s) / 자리변경(w)
        .btn_UP(btn_UP),  // mode(s) / up(w)
        .btn_DOWN(btn_DOWN),  // option(s) / down(w)
        .sw(sw),  // sw[0]: 0-stopwatch / 1:watch
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .led(led)  // indicator
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        btn_L = 0;
        btn_R = 0;
        btn_UP = 0;
        btn_DOWN = 0;
        sw = 3'b010; // watch 모드
        #10; 
        reset = 0;

        #(TICK_DELAY*3); //btn_R 누름
        btn_R = 1;
        #(TICK_DELAY*3); 
        btn_R = 0;

        #(TICK_DELAY);
        btn_R = 1;
        #(TICK_DELAY*3); 
        btn_R = 0;

        #(TICK_DELAY);
        btn_R = 1;
        #(TICK_DELAY*3); 
        btn_R = 0;

        #(TICK_DELAY);
        btn_R = 1;
        #(TICK_DELAY*3); 
        btn_R = 0;

        #(TICK_DELAY);

        #(TICK_DELAY); //btn_L 누름
        btn_L = 1;
        #(TICK_DELAY*3); 
        btn_L = 0;

        #(TICK_DELAY);
        btn_L = 1;
        #(TICK_DELAY*3); 
        btn_L = 0;

        #(TICK_DELAY);
        btn_L = 1;
        #(TICK_DELAY*3); 
        btn_L = 0;

        #(TICK_DELAY);
        btn_L = 1;
        #(TICK_DELAY*3); 
        btn_L = 0;

        #(TICK_DELAY);
        btn_L = 1;
        
        
        $stop;
    end

endmodule
```

> btn_R 정방향 11→00→01→10, btn_L 역방향 11→10→01→00 확인. (버튼이 눌린 다음 posedge에 변이)
> 

//시뮬 사진 고쳤어!

![waveform_annotated.png](waveform_annotated.png)

#### 5-3-2.  watch datapath 모듈 설계 및 테스트벤치

![496E8666-8ED1-46F7-A118-76A995E94543.jpeg](496E8666-8ED1-46F7-A118-76A995E94543.jpeg)

- tick_gen_100hz는 stopwatch에서 작성한 것을 그대로 재사용.

#### (a) demux_1x3 — 조정 신호 라우팅

- **동작 개념(소스 전)**: 현재 state에 따라 up/down 버튼을 hour/min/sec **한 자리로만** 흘려보냄.

```verilog
module demux_1x3 (
    input [1:0] sel,
    input i_btn,
    output reg [2:0] o_btn
);
    always @(*) begin
        case (sel)
            2'b00: o_btn = 3'b000;                  // start = 선택 안됨
            2'b01: o_btn = {{i_btn}, 2'b00};        // hour
            2'b10: o_btn = {1'b0, {i_btn}, 1'b0};   // min
            2'b11: o_btn = {2'b00, {i_btn}};        // sec
        endcase
    end
endmodule
```

#### (b) watch_time_counter — up/down 조정 카운터

- **동작 개념(소스 전)**: `time_counter` + 시간 맞추기(up/down) 입력. `INIT_NUM`으로 초기값 지정(HOUR=12).

```verilog
module watch_time_counter #(
    parameter COUNT_NUM = 100, INIT_NUM = 0
) (
    input clk, input reset, input i_tick,
    input i_up, input i_down,
    output reg [$clog2(COUNT_NUM)-1:0] time_cnt,
    output reg o_tick
);
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            time_cnt <= INIT_NUM;
            o_tick   <= 1'b0;
        end else begin
            if (i_tick) begin
                time_cnt <= time_cnt + 1;
                if (time_cnt == COUNT_NUM - 1) begin
                    time_cnt <= 0;
                    o_tick   <= 1'b1;
                end
            end else begin
                o_tick <= 1'b0;
            end
            if (i_up)   time_cnt <= time_cnt + 1;
            if (i_down) time_cnt <= time_cnt - 1;
        end
    end
endmodule
```

#### (c) watch_datapath — 조정 가능한 시계 카운터 통합 (박정민) *(테스트 有)*

- **동작 개념**
    - tick 체인은 stopwatch와 동일하되, up/down을 demux로 state에 맞는 자리로만 보내 조정.
    - HOUR 초기값 12(=12:00:00:00).
- **블럭도/schematic**

![496E8666-8ED1-46F7-A118-76A995E94543.jpeg](496E8666-8ED1-46F7-A118-76A995E94543.jpeg)

```verilog
module watch_datapath (
    input clk, input reset,
    input up, input down,
    input [1:0] state,
    output [6:0] msec, output [5:0] sec, output [5:0] min, output [4:0] hour
);
    wire o_tick_msec, o_tick_sec, o_tick_min, o_tick_hour;
    wire w_up_sec, w_up_min, w_up_hour;
    wire w_down_sec, w_down_min, w_down_hour;

    tick_gen_100hz U_TICK_GEN (.clk(clk), .reset(reset), .o_tick(o_tick_msec));

    demux_1x3 U_DMUX_UP   (.sel(state), .i_btn(up),   .o_btn({w_up_hour,   w_up_min,   w_up_sec}));
    demux_1x3 U_DMUX_DOWN (.sel(state), .i_btn(down), .o_btn({w_down_hour, w_down_min, w_down_sec}));

    watch_time_counter #(.COUNT_NUM(100)) U_WATCH_COUNTER_MSEC (
        .clk(clk), .reset(reset), .i_tick(o_tick_msec),
        .i_up(1'b0), .i_down(1'b0),      // msec는 조정 안 함
        .time_cnt(msec), .o_tick(o_tick_sec));
    watch_time_counter #(.COUNT_NUM(60)) U_WATCH_COUNTER_SEC (
        .clk(clk), .reset(reset), .i_tick(o_tick_sec),
        .i_up(w_up_sec), .i_down(w_down_sec),
        .time_cnt(sec), .o_tick(o_tick_min));
    watch_time_counter #(.COUNT_NUM(60)) U_WATCH_COUNTER_MIN (
        .clk(clk), .reset(reset), .i_tick(o_tick_min),
        .i_up(w_up_min), .i_down(w_down_min),
        .time_cnt(min), .o_tick(o_tick_hour));
    watch_time_counter #(.COUNT_NUM(24), .INIT_NUM(12)) U_WATCH_COUNTER_HOUR (
        .clk(clk), .reset(reset), .i_tick(o_tick_hour),
        .i_up(w_up_hour), .i_down(w_down_hour),
        .time_cnt(hour), .o_tick());
endmodule
```

**✔ 테스트 검증**

```verilog
module tb_watch_datapath ();
    parameter TICK_DELAY = 1_000_000 * 10;
    reg clk, reset, up, down; reg [1:0] state;
    wire [6:0] msec; wire [5:0] sec, min; wire [4:0] hour;

    watch_datapath dut (
        .clk(clk), .reset(reset), .up(up), .down(down), .state(state),
        .msec(msec), .sec(sec), .min(min), .hour(hour));
    always #5 clk = ~clk;
    initial begin
        clk=0; reset=1; up=0; down=0; state=2'b00; #10; reset=0;
        #(TICK_DELAY*10); state=2'b01; #6; up=1; #10; up=0;    // hour +1
        #(TICK_DELAY*10); state=2'b10; #6; up=1; #10; up=0;    // min +1
        #(TICK_DELAY*10); state=2'b11; #6; up=1; #10; up=0;    // sec +1
        #(TICK_DELAY*10); state=2'b01; #6; down=1; #10; down=0; // hour -1
        // ... min/sec down 동일
    end
endmodule
```

- 아직 top 미연결이라 debounce 안 된 버튼으로 테스트.

![image.png](image%2014.png)

- 초기화 상태 확인 12:00:00:00

![image.png](image%2015.png)

- up 버튼 입력이 clk posedge에 반영
- state 01:  hour 변경 허용하는 state
- hour 변경 state + up 버튼 입력 = hour 0 → 1

![image.png](image%2016.png)

- down 버튼 입력이 clk posedge에 반영
- state 01: hour 변경 허용하는 state
- hour 변경 state + down 버튼 입력 = hour 1 → 0

#### 5-3-3. top 모듈에서 watch 연결

- **연결 설명**
    - 버튼을 `& sw[1]`로 게이팅(=watch 모드일 때만 반응).
    - btn_L/R은 자리 이동(FSM), btn_UP/DOWN은 up/down 조정.
    - 출력 시간은 `w_*_watch`로 나가되, **hour는 12/24 변환을 거쳐** top mux로 들어가고, 조정 중인 자리는 **state_decoder+indicator**로 점멸

#### (1) watch control unit · datapath 인스턴스

```verilog
    // watch control unit  (sw[1]=1 일 때만 버튼 반응)
    watch_control_unit U_CNTL_UNIT_WATCH (
        .clk(clk), .reset(reset),
        .btn_L(w_btn_L & sw[1]), .btn_R(w_btn_R & sw[1]),
        .state(w_state));

    // watch datapath
    watch_datapath U_DATAPATH_WATCH (
        .clk(clk), .reset(reset),
        .up(w_btn_UP & sw[1]), .down(w_btn_DOWN & sw[1]), .state(w_state),
        .msec(w_msec_watch), .sec(w_sec_watch), .min(w_min_watch), .hour(w_hour_watch));
```

#### (2) 12/24시간제 변환 (방지윤)

- **동작 개념**: 내부 hour는 항상 0~23. 표시 직전 `sw[2]=1`이면 1323→111, 0→12로 변환. watch(`sw[1]=1`)일 때만 최종 hour에 반영.

```verilog
    // watch 12시간제
    wire w_format12_watch;
    reg  [4:0] w_hour_display_watch;
    assign w_format12_watch = sw[2];
    always @(*) begin
        w_hour_display_watch = w_hour_watch;                       // sw[2]=0 -> 24시간제
        if (w_format12_watch) begin
            if (w_hour_watch > 12)      w_hour_display_watch = w_hour_watch - 12;  // 13~23 -> 1~11
            else if (w_hour_watch == 0) w_hour_display_watch = 12;                 // 0 -> 12
        end
    end

    // 최종 hour: watch면 12/24 변환값, stopwatch면 그대로
    assign w_hour = (sw[1]) ? w_hour_display_watch : w_hour_stopwatch;
    assign w_fnd_state = (sw[1]) ? w_state : 2'b00;   // stopwatch면 점멸 없음
```

#### (3) 조정 자리 점멸 — state_decoder + indicator (방지윤)

![image.png](image%2017.png)

- **동작 개념**: FSM의 2비트 state를 “어느 자리를 깜빡일지” 4비트로 바꾸고(state_decoder), 그 자리에 대해 comp 주기로 숫자↔︎꺼짐을 번갈아 출력(indicator). fnd_controller에 포트를 추가해 얹는다.

| state | state_out | 깜빡이는 자리 |
| --- | --- | --- |
| 00 | 0000 | 없음 |
| 01 | 1000 | hour |
| 10 | 0100 | min |
| 11 | 0010 | sec |

```verilog
module state_decoder (
    input clk, input reset,
    input [1:0] state,
    output reg [3:0] state_out
);
    always @(state) begin
        case (state)
            2'b00:   state_out = 4'b0000;
            2'b01:   state_out = 4'b1000;
            2'b10:   state_out = 4'b0100;
            2'b11:   state_out = 4'b0010;
            default: state_out = 4'b0000;
        endcase
    end
endmodule

module indicator (
    input clk, input reset,
    input [1:0] sw, input comp, input state,
    input [3:0] digit_1, input [3:0] digit_10,
    output reg [3:0] indi_digit_1, output reg [3:0] indi_digit_10
);
    always @(*) begin
        if (comp && state) begin
            indi_digit_1  = 4'hf;   // 꺼짐
            indi_digit_10 = 4'hf;
        end else begin
            indi_digit_1  = digit_1;
            indi_digit_10 = digit_10;
        end
    end
endmodule
```

- **코드 설명**: 조정 중인 자리(state=1) & comp=1 구간에 숫자 대신 `4'hf`(꺼짐) → 50ms 주기 점멸(comp=msec<50). `w_fnd_state`가 fnd_controller로 전달돼 각 자리 indicator의 state 입력이 된다.

**✔ 테스트 검증 (top 통합: watch 조정 · indicator · 12/24시간제)**

```verilog
`timescale 1ns / 1ps
module tb_watch_and_stopwatch_top ();
    parameter TICK_DELAY = 1_000_000 * 10;
    reg clk, reset, btn_L, btn_R, btn_UP, btn_DOWN; reg [2:0] sw;
    wire [3:0] fnd_com; wire [7:0] fnd_data; wire [1:0] led;

    top_stopwatch dut (
        .clk(clk), .reset(reset), .btn_L(btn_L), .btn_R(btn_R),
        .btn_UP(btn_UP), .btn_DOWN(btn_DOWN), .sw(sw),
        .fnd_com(fnd_com), .fnd_data(fnd_data), .led(led));
    always #5 clk = ~clk;
    initial begin
        clk=0; reset=1; btn_L=0; btn_R=0; btn_UP=0; btn_DOWN=0; sw=3'b000;
        #10; reset=0;
        // stopwatch
        #(TICK_DELAY*5); btn_L=1; #(10_000); btn_L=0;
        // watch (24시)
        #(TICK_DELAY*10); sw=3'b010; #100;
        #6; btn_R=1; #(10_000); btn_R=0;   // hour 선택
        #6; btn_UP=1; #(10_000); btn_UP=0; // hour 증가
        #(TICK_DELAY*2);
        sw=3'b110; #(TICK_DELAY*2);         // 12시간제
        sw=3'b010; #(TICK_DELAY*2);         // 24시간제
        $stop;
    end
endmodule
```

![image.png](image%2018.png)

- sw 000→0 표시(stopwatch) / 010→13(watch 24시) / 110→1(watch 12시) / 010→13.
- 조정 상태에서 해당 자리 50ms 점멸 확인.

---

## 6. FPGA 보드 동작 영상 및 설명

> [영상/이미지 자리]
- stopwatch: runstop / clear / mode / (save→load) 동작.
- watch: 자리 이동(btn_L/R) → up/down 조정 → 조정 자리 점멸.
- 12↔24시간제 전환(sw[2])
> 

---

## 7. 트러블슈팅 (as-is / to-be)

### 1. time_counter o_tick 지속 유지 버그

- **as-is**: 상위 자리 tick(`o_tick`)이 1로 유지 → sec·min·hour가 매 clk cycle마다 증가.
- **원인**: `i_tick`이 없을 때 `o_tick`을 0으로 내리는 분기가 `if(i_tick)` 내부에만 있었음.
- **to-be**: `i_tick`과 무관하게 다음 posedge에 `o_tick`을 바로 0으로 내리도록 else로 이동.
- 변경 전 오류동작 시뮬레이션
    - 오류 동작 → sec tick이 계속 1이니까 sec와 min, hour count가 매 clk cycle마다 증가

```verilog
if (i_tick) begin
    time_cnt <= time_cnt + 1;
    if (time_cnt == (COUNT_NUM - 1)) begin
        time_cnt <= 0; o_tick <= 1'b1;
    end
end else begin
    o_tick <= 1'b0;   // 매 clk마다 0으로
end
```

- **결과**: msec 99→0 되는 다음 clk에 sec가 1회만 증가.

### 2. basys3에서 save/load 미동작 — down 버튼이 run처럼 작동

- **as-is**: 시뮬레이션에서는 save/load가 정상 동작했으나, **FPGA 보드에서는 down 버튼을 눌러도 저장/불러오기가 되지 않고 stopwatch가 run되는 현상** 발생.
- **원인**: `control_unit`의 상태 인코딩에서 **`LOAD`가 `RUN`과 값이 동일**함.

```verilog
parameter STOP = 3'b000, RUN = 3'b001, CLEAR = 3'b010, MODE = 3'b011, SAVE = 3'b100, LOAD = 3'b001;
//                             ^^^^^^^                                              LOAD = 3'b001 (RUN과 충돌)
```

- STOP에서 (저장 데이터 있음 + down) → `n_state = LOAD(3'b001)`.
- 다음 posedge에 `c_state = 3'b001` → `case(c_state)`에서 **RUN 라벨이 먼저 매치** → `run_stop_next = 1'b1` → 스톱워치가 run 상태로 진입.
- 즉 LOAD 분기는 실행되지 않아 `o_load`가 발생하지 않고, down이 사실상 run 토글로 동작.
- **시뮬에서 못 잡은 이유**: `tb_stopwatch_save_load`는 control_unit을 거치지 않고 datapath에 `save`/`load`를 **직접 인가**해 검증 → control unit의 인코딩 충돌이 드러나지 않았음. (top 레벨 테스트에는 save/load 시나리오가 없었음)
- **to-be**: LOAD state 값 수정 `3'b101`  후 보드에서 정상 작동 검증
- 변경 전 오류상황 시뮬레이션

![unnamed.png](unnamed.png)

- down 버튼 입력으로 i_save_load 신호 1 → n_state 업데이트 STOP(000) → LOAD(001)로 업데이트
- RUN , LOAD가 001 상태값을 공유하므로 case문에서 상단에 위치한 run이 먼저 채택 → runstop이 출력 (오류 동작)

```verilog
parameter STOP = 3'b000, RUN = 3'b001, CLEAR = 3'b010, MODE = 3'b011, SAVE = 3'b100, LOAD = 3'b101;
```

- 변경 후 시뮬레이션

![image.png](image%2019.png)

- down 버튼 입력으로 i_save_load가 1 → n_state  STOP(000)에서 SAVE(100)으로 업데이트
- 다음 clk posedge에 c_state = n_state 반영 → 반영 후 c_state SAVE(100)
- 다음 clk posedge에 o_save 출력 → datapath에서 현재 stopwatch 타이머값 저장 트리거

### 3. 12시간제 변환 시 자정(00시) 표시 오류

- as-is : 
12시간제 변환 시 단순 뺄셈(`hour - 12`)만 적용하여 자정인 `00시`가 `00시`로 그대로 표시되거나 예외 동작 발생

오류 시뮬 사진

- **원인 :** `13~23시`는 `12`를 빼면 `1~11시`로 정상 변환되지만, `00시`일 때 `12 AM`으로 출력해야 하는 예외 조건 처리가 누락됨.
- **be :** `w_hour_watch == 0` 조건을 별도로 분리하여 자정(`00시`) 입력 시 `12`가 출력되도록 예외 처리 추가.
    
    ```jsx
    always @(*) begin
        w_hour_display_watch = w_hour_watch;
        if (w_format12_watch) begin
            if (w_hour_watch > 12) 
                w_hour_display_watch = w_hour_watch - 12; // 13~23시 -> 1~11시
            else if (w_hour_watch == 0) 
                w_hour_display_watch = 12;             // 00시 예외 처리 (12시 출력)
        end
    end
    ```
    
- **결과 :** 12시간제 모드 전환 시 자정(`00시`)이 정확히 `12`로 표시되고, 13~23시 역시 1~11시로 정상 변환됨.

---

## 8. 결과 및 분석

### 결과

- stopwatch·watch 두 모드를 하나의 top에 통합, `sw`로 전환하며 동작 확인.
- watch 추가기능: 조정 자리 점멸·12/24시간제 보드 정상 동작 확인
- stopwatch 추가기능: save/load 보드 정상 동작 확인
- 모든 기능과 추가기능 시뮬레이션 및 보드 정상 동작 검증 완료

### 분석

- **파라미터 재사용**으로 카운터를 단일 모듈로 유지하며 진법만 바꿔 체인 구성.
- **datapath / control unit 분리** + 저장 플래그 피드백(`o_is_data_saved`)으로 SAVE/LOAD 분기를 처리.
- **버튼 게이팅(`& sw[1]`)** 으로 버튼 세트를 두 모드가 공유.
- **12시간제**는 표시 직전 조합논리로만 변환해 내부 카운트(0~23)는 변경 없음

---