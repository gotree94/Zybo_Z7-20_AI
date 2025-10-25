# 🧩 Zybo Z7-20 기반 인공지능 통합 교육 커리큘럼 (6주 완성형)

## 목표: “FPGA + AI + 임베디드 리눅스 + HLS + 영상처리” 전 과정을 실제 보드 하나로 학습

###  📘 1 주차 — Zynq SoC 구조 및 Vivado 기초
   * 목표: Zynq PS/PL 통합 개념 습득, Vivado 환경 숙달
   * 이론: Zynq 아키텍처, AXI 인터페이스, GPIO 통신 원리
   * 실습:
      * Vivado Block Design 으로 Zynq PS 설정
      * PL 측 Verilog LED 토글 모듈 작성
      * SDK 또는 Vitis 에서 C 코드로 PS–PL 통신 테스트

---

### 1주차 목표
   * Zynq(PS)–FPGA(PL) 구조와 AXI 인터페이스 감 잡기
   * Vivado에서 Zynq PS + AXI GPIO 블록 디자인 생성
   * 보드의 LED를 AXI GPIO로 제어 (Vitis에서 C 코드 실행)
   * 다음 주차(HLS/CNN 가속)로 넘어갈 XSA 내보내기 흐름 익히기
### 준비물
   * 보드: Zybo Z7-20 (전원 어댑터 or USB)
   * 케이블: Micro-USB (JTAG/UART 통합), HDMI/센서 없음
   * PC 도구: Vivado + Vitis (동일 연도 버전), Digilent 보드 파일(있으면 편함), USB JTAG 드라이버
   * 콘솔: Vitis의 JTAG UART(또는 TeraTerm/Putty, “JTAG UART” 선택)
   * 버전은 2022.2~2024.x 아무거나 한 세대로 통일하세요. (Vivado와 Vitis는 같은 버전 사용)

---

### 0. 하드웨어 점검 (5분)
   1. JP6(JTAG/USB Boot) 점퍼를 JTAG로 두고, Micro-USB를 PC에 연결
   2. Power 스위치 ON → 보드 전원 LED 점등 확인
   3. Device Manager(Windows)에서 “Xilinx USB Cable” 또는 JTAG 장치 인식 확인

---

### 1. Vivado 프로젝트 & 보드 파일 적용 (10분)
   1. Vivado 실행 → Create Project
   2. Name/Location 지정 → RTL Project (Sources/Constraints는 비워둬도 됨)
   3. Boards 탭에서 Zybo Z7-20 선택
      * 만약 목록에 없으면: Digilent의 Zybo Z7 보드 파일을 설치(보드 파일 없이도 진행 가능하지만, 있으면 Pin/Interface 매핑이 쉬움)
   4. 프로젝트 생성 완료

---

### 2. 블록 디자인: Zynq PS + AXI GPIO + Reset (20분)
   1. Create Block Design → 이름 design_1
   2. Add IP → ZYNQ7 Processing System 추가
      * Run Block Automation 실행 → DDR/Fixed IO 자동 연결
   3. Add IP → AXI GPIO 추가
      * GPIO 채널을 LED 4개에 쓸 것이므로 GPIO width = 4, All outputs로 설정
   4. Add IP → AXI Interconnect (마스터=PS, 슬레이브=GPIO)
   5. Add IP → Processor System Reset (ps7의 FCLK/ARESETN 연결용)
   6. 연결
      * PS의 M_AXI_GP0 → AXI Interconnect (M00_AXI)
      * AXI Interconnect (S00_AXI) → AXI GPIO (S_AXI)
      * Clock/Reset: PS의 FCLK_CLK0 → Interconnect/AXI GPIO/Processor System Reset의 slowest_sync_clk에 공통 연결
      * PS의 FCLK_RESET0_N → Processor System Reset의 ext_reset_in
      * Processor System Reset의 peripheral_aresetn → AXI GPIO s_axi_aresetn
   7. AXI GPIO의 GPIO 포트를 External로 내보내기 (그림자 포트 gpio_io_o[3:0] 생성됨 → 나중에 LED 핀으로 제약)
   * 팁: Address Editor에서 AXI GPIO가 0x4000_0000 같은 베이스 주소를 자동 할당 받습니다. (Vitis에서 드라이버가 이걸 사용)

---

### 3. 제약(XDC)으로 LED 핀 매핑 (10분)
   * Digilent가 제공하는 Zybo Z7-20 master XDC에서 LED 핀 라인만 활성화해서 사용하면 가장 안전합니다.
   * 블록 디자인에서 만든 외부 포트 이름이 gpio_io_o[3:0] 라면, XDC에서 다음처럼 net 이름을 맞춰주세요. (예시는 형식만 보여주는 것이고, 실제 핀명은 Digilent XDC에서 Zybo Z7-20용 LED 핀으로 정확히 사용하세요.)

```xdc
## User LEDs (Zybo Z7-20 Master XDC에서 해당 라인 활성화)
set_property PACKAGE_PIN <LED0_PIN> [get_ports {gpio_io_o[0]}]
set_property IOSTANDARD LVCMOS33   [get_ports {gpio_io_o[0]}]

set_property PACKAGE_PIN <LED1_PIN> [get_ports {gpio_io_o[1]}]
set_property IOSTANDARD LVCMOS33   [get_ports {gpio_io_o[1]}]

set_property PACKAGE_PIN <LED2_PIN> [get_ports {gpio_io_o[2]}]
set_property IOSTANDARD LVCMOS33   [get_ports {gpio_io_o[2]}]

set_property PACKAGE_PIN <LED3_PIN> [get_ports {gpio_io_o[3]}]
set_property IOSTANDARD LVCMOS33   [get_ports {gpio_io_o[3]}]
```
   * m중요: 실제 핀 이름은 보드의 Master XDC에서 “LED”로 표시된 줄을 사용하세요. (보드 파일이 있으면 Board 탭에서 LED 인터페이스로 매핑도 가능)

---

### 4. Synthesis/Implementation/Bitstream & XSA 내보내기 (10~20분)
   1. Validate Design → 경고/에러 없으면 OK
   1. Generate HDL Wrapper (Let Vivado manage it)
   1. Run Synthesis → Implementation → Generate Bitstream
   1. 완료 후 File → Export → Export Hardware…
      * Include bitstream 체크
      * 내보낸 XSA 파일 경로 확인 (다음 단계 Vitis에서 사용)

---

### 5. Vitis(Bare-metal)에서 LED 토글 앱 (20분)
   1. Vitis 실행 → Create Application Project
      * Platform: 방금 Export한 XSA 선택 (또는 Import)
      * Application: Empty Application (또는 Hello World)
   2. BSP에 xgpio 드라이버 포함 확인
   3. src/main.c 에 다음과 같이 작성:

```c
#include "xgpio.h"
#include "xparameters.h"
#include "xil_printf.h"
#include "sleep.h"

#define GPIO_DEV_ID XPAR_GPIO_0_DEVICE_ID   // Vitis가 생성한 xparameters.h에서 확인
#define LED_CHANNEL 1                       // AXI GPIO 채널 1 사용 (단일 채널일 때 보통 1)

int main() {
    XGpio gpio;
    int status = XGpio_Initialize(&gpio, GPIO_DEV_ID);
    if (status != XST_SUCCESS) {
        xil_printf("GPIO init failed\r\n");
        return -1;
    }

    // 채널 방향: 출력(=0). 단, XGpio_SetDataDirection에서 비트가 1이면 입력, 0이면 출력.
    XGpio_SetDataDirection(&gpio, LED_CHANNEL, 0x0); // 4비트 모두 출력

    xil_printf("Zybo Z7-20 LED blink start\r\n");

    uint32_t pat = 0x1;
    while (1) {
        XGpio_DiscreteWrite(&gpio, LED_CHANNEL, pat & 0xF); // 하위 4비트만
        usleep(100*1000);
        pat = (pat << 1);
        if (pat > 0x8) pat = 0x1;
    }
    return 0;
}
```
   4. 빌드 → Program Device (Vitis에서 자동으로 Bitstream+ELF 다운로드)
   5. Vitis Console(JTAG UART)에 Zybo Z7-20 LED blink start 출력 확인, 보드의 LED가 좌→우로 순차 점멸되면 성공

### 6. 검증 체크리스트
   * 보드 전원/케이블/부트 점퍼(JTAG) OK
   * Vivado Block Design: PS7 + AXI GPIO + AXI Interconnect + Proc Sys Reset 연결 완료
   * AXI GPIO의 gpio_io_o[3:0]를 External로 내보내고, LED 핀 제약(XDC) 적용
   * Bitstream 생성 & XSA 내보내기(Include bitstream)
   * Vitis에서 xgpio로 LED 토글 성공, 콘솔 메시지 확인

### 7. 흔한 이슈 & 해결

[NSTD-1 / UCIO-1] I/O Standard/LOC 미지정 에러
↳ Master XDC에서 LED 핀 라인 활성화 했는지 확인 (IOSTANDARD = LVCMOS33, LOC = 각 LED의 패키지핀)

GPIO가 안 깜빡임
↳ (1) XGpio_SetDataDirection(..., 0x0)로 출력 설정했는지
↳ (2) 채널 번호(보통 1)와 비트폭(4비트) 일치 확인
↳ (3) Address Editor에서 AXI 주소 할당 및 XPAR_GPIO_0_DEVICE_ID 매칭 확인

콘솔 출력이 안 보임
↳ Vitis 콘솔이 JTAG UART에 연결됐는지 확인(또는 UART 포트 선택)

8. 1주차 산출물(당신이 보드에서 직접 만들 것)

Vivado 프로젝트(design_1) + Bitstream

XSA (Include bitstream)

Vitis 워크스페이스(Platform + App)

main.c(LED 토글) 실행 로그 스크린샷/메모

9. 다음 주(2주차) 예고

Verilog IP 모듈(FSM/ALU/UART) 추가하고, AXI4-Lite 슬레이브 템플릿으로 PS에서 레지스터 접근

간단한 Sim/xsim 파형 검증과 함께, 보드 LED/스위치/버튼 매핑 실습
