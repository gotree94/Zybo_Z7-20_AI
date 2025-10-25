# 🧠 Zybo Z7-20 Edge AI 통합 교육 워크북 – 2주차  
## Verilog IP 설계 및 AXI Slave 인터페이스 실습

---

## 🎯 학습 목표
- FPGA 내부에 사용자 정의 Verilog IP를 생성하고 AXI4-Lite 인터페이스로 Zynq PS와 통신한다.  
- PS에서 레지스터를 읽고 쓰는 방법을 익히고, 기본 연산(ALU)을 수행해본다.  
- Vivado의 IP Packager를 활용하여 사용자 IP를 Block Design에 추가한다.

---

## 🧩 1. 준비 사항

| 항목 | 내용 |
|------|------|
| 보드 | Zybo Z7-20 |
| 툴 | Vivado + Vitis (2022.2 이상) |
| 프로젝트 | `Zybo_AXI_Slave` |
| 주요 학습 포인트 | Verilog IP 생성, AXI 인터페이스 구조, Register Mapping |

---

## 🧱 2. AXI4-Lite 구조 요약

AXI4-Lite는 ARM Cortex-A9(PS)와 사용자 IP(PL) 간 **저속 제어용 버스**입니다.  
- **주소 공간 기반 통신** (PS가 32bit 레지스터 주소로 접근)  
- **데이터 폭:** 32bit  
- **단일 전송 구조** (burst 없음)

| 채널 | 역할 |
|------|------|
| AW | Address Write |
| W | Data Write |
| B | Write Response |
| AR | Address Read |
| R | Data Read |

---

## 🧠 3. Vivado IP Template 생성

1. **Vivado 실행 → Tools → Create and Package New IP**
2. 선택  
   - **Create a new AXI4 peripheral**  
   - Name: `my_axi_alu`  
   - Location: 프로젝트 경로 내 `ip_repo` 폴더
3. Interface  
   - Bus Interface: **S_AXI (AXI4-Lite)**  
   - Number of Registers: **4개** (a, b, opcode, result)
4. Finish → Verilog Template 자동 생성

---

## 🧾 4. Verilog 코드 수정

`my_axi_alu_v1_0_S00_AXI.v` 파일의 `user logic` 부분을 아래처럼 수정합니다.

```verilog
//---------------------------------------------------------
// User Logic : Simple 8-bit ALU (AXI4-Lite Control)
//---------------------------------------------------------
reg [7:0] reg_a, reg_b, reg_opcode;
reg [15:0] reg_result;

always @(posedge S_AXI_ACLK) begin
  if (!S_AXI_ARESETN) begin
    reg_a <= 0;
    reg_b <= 0;
    reg_opcode <= 0;
    reg_result <= 0;
  end else begin
    // Write registers
    if (slv_reg_wren) begin
      case (axi_awaddr[3:2])
        2'b00: reg_a <= S_AXI_WDATA[7:0];
        2'b01: reg_b <= S_AXI_WDATA[7:0];
        2'b10: reg_opcode <= S_AXI_WDATA[2:0];
      endcase
    end

    // Simple ALU logic
    case (reg_opcode)
      3'b000: reg_result <= reg_a + reg_b;
      3'b001: reg_result <= reg_a - reg_b;
      3'b010: reg_result <= reg_a & reg_b;
      3'b011: reg_result <= reg_a | reg_b;
      3'b100: reg_result <= reg_a ^ reg_b;
      default: reg_result <= 16'h0000;
    endcase
  end
end

// Read registers
always @(*) begin
  case (axi_araddr[3:2])
    2'b00: reg_data_out = {24'd0, reg_a};
    2'b01: reg_data_out = {24'd0, reg_b};
    2'b10: reg_data_out = {29'd0, reg_opcode};
    2'b11: reg_data_out = {16'd0, reg_result};
    default: reg_data_out = 0;
  endcase
end
```

✅ 이 코드로 PS에서

REG0 = 입력 A

REG1 = 입력 B

REG2 = 연산 코드 (opcode)

REG3 = 결과 값

을 AXI 주소 공간에서 직접 제어할 수 있습니다.

⚙️ 5. IP Packager 등록 및 Vivado Block Design 통합

Tools → Create and Package New IP → Package IP

Repository 위치를 ip_repo 로 설정

Vivado → Project Settings → IP Repository 경로에 ip_repo 추가

Block Design 열기 → Add IP → my_axi_alu 추가

S_AXI → PS의 M_AXI_GP0 연결

aclk → PS의 FCLK_CLK0, aresetn → Processor System Reset의 peripheral_aresetn 연결

Address Editor → 자동 주소 할당 확인 (예: 0x43C0_0000)

LED 출력을 추가하려면 result[3:0]을 External 로 Export 후 LED 핀 매핑 (선택)

🧰 6. Bitstream 생성 및 XSA 내보내기

Validate Design

Generate HDL Wrapper

Run Synthesis → Implementation → Generate Bitstream

Export Hardware (Include Bitstream) → my_axi_alu.xsa

💻 7. Vitis에서 제어 코드 작성

main.c 파일:

#include "xil_io.h"
#include "xparameters.h"
#include "xil_printf.h"
#include "sleep.h"

#define ALU_BASE XPAR_MY_AXI_ALU_0_S00_AXI_BASEADDR

int main() {
    u32 a = 5, b = 3, opcode, result;
    xil_printf("Zybo Z7-20 AXI ALU test start\r\n");

    for (opcode = 0; opcode < 5; opcode++) {
        Xil_Out32(ALU_BASE + 0x0, a);
        Xil_Out32(ALU_BASE + 0x4, b);
        Xil_Out32(ALU_BASE + 0x8, opcode);
        result = Xil_In32(ALU_BASE + 0xC);
        xil_printf("a=%d, b=%d, opcode=%d → result=%d\r\n", a, b, opcode, result);
        sleep(1);
    }

    xil_printf("Test done.\r\n");
    return 0;
}


✅ 콘솔 출력 예시:

Zybo Z7-20 AXI ALU test start
a=5, b=3, opcode=0 → result=8
a=5, b=3, opcode=1 → result=2
a=5, b=3, opcode=2 → result=1
a=5, b=3, opcode=3 → result=7
a=5, b=3, opcode=4 → result=6
Test done.

🧩 8. 검증 포인트 체크리스트
항목	확인
[ ] PS → AXI → my_axi_alu 연결 완료	
[ ] Address Editor 에 베이스 주소 등록됨	
[ ] IP의 레지스터 4개 정상 동작	
[ ] Vitis 콘솔에서 연산 결과 확인 가능	
[ ] Reset 후 다시 접근 시 정상	
🚀 9. 확장 아이디어

버전 2 실습: LED 또는 7-Segment에 결과값 표시

버전 3 실습: UART 통해 a, b, opcode 입력 받아서 실시간 연산

버전 4 실습: PS에서 DMA를 통해 대량의 데이터 연산 (HLS와 연계 예정)

### 📂 결과물 정리 (Git 구조 예시)
```
ZyboAI/
└── week02_axi_slave/
    ├── vivado_project/
    │   ├── ip_repo/my_axi_alu/
    │   └── design_1/
    ├── vitis_app/
    │   ├── src/main.c
    │   └── system/platform/
    └── README.md
```

### ✅ 다음 주차(3주차):
   * Vivado HLS를 이용한 Conv2D / Sobel 필터 가속기 설계로 확장합니다.
   * HLS IP를 AXI Stream + DMA 방식으로 연결하고, PS에서 가속기 제어를 실습합니다.

### 사용 안내 (요약)
   1. Vivado 열고 create_alu_project.tcl을 소스하세요.
      * Vivado Tcl 콘솔 →  source /full/path/to/create_alu_project.tcl
      * 프로젝트/BD 생성, PS7 설정, proc_sys_reset, (IP repo에 있을 경우) my_axi_alu 자동 연결, 비트스트림 생성, XSA까지 자동 진행됩니다.
      * my_axi_alu IP가 아직 패키지되지 않았다면, 스크립트가 그 상태로 넘어가며 안내 메시지를 출력합니다. (나중에 ip_repo에 IP 추가 후 다시 배선/주소 할당 부분만 재실행하면 됩니다.)
   2. Vitis에서 방금 생성된 XSA를 Platform으로 사용한 뒤, main.c를 앱에 넣고 빌드 → Program Device 하면 됩니다.
      * 베이스 주소는 자동 생성된 xparameters.h의 XPAR_MY_AXI_ALU_0_S00_AXI_BASEADDR를 사용합니다(스크립트에도 안전장치 포함).
