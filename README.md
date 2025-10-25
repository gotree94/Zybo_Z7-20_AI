# 🧩 Zybo Z7-20 기반 인공지능 통합 교육 커리큘럼 (6주 완성형)

## 목표: “FPGA + AI + 임베디드 리눅스 + HLS + 영상처리” 전 과정을 실제 보드 하나로 학습

###  📘 1 주차 — Zynq SoC 구조 및 Vivado 기초
   * 목표: Zynq PS/PL 통합 개념 습득, Vivado 환경 숙달
   * 이론: Zynq 아키텍처, AXI 인터페이스, GPIO 통신 원리
   * 실습:
      * Vivado Block Design 으로 Zynq PS 설정
      * PL 측 Verilog LED 토글 모듈 작성
      * SDK 또는 Vitis 에서 C 코드로 PS–PL 통신 테스트

###  ⚙️ 2 주차 — Verilog 기초 및 하드웨어 IP 모듈
   * 목표: FPGA 로직 설계와 테스트 벤치 이해
   * 이론: FSM, ALU, I2C/SPI 마스터, UART TX/RX 구조
   * 실습:
      * UART TX/RX Verilog 설계 → PL 측 AXI Slave 연결
      * SDK/Vitis 에서 PS 코드로 데이터 송수신
      * 파형 시뮬레이션 (xsim or xrun) 실습

### 🧠 3 주차 — Vivado HLS 및 AI 가속기 입문
   * 목표: HLS 기반 CNN 연산 모듈 제작
   * 이론: HLS C/C++ 합성 흐름, AXI4-Stream 인터페이스, CNN 연산 기초
   * 실습:
      * C++로 Sobel Filter / Conv2D 모듈 작성
      * Vivado HLS → IP 합성 → Vivado Block Design 삽입
      * PS 에서 데이터 전송 및 FPGA 가속 결과 확인

### 🧰 4 주차 — PetaLinux 및 임베디드 AI 환경 구축
   * 목표: Zybo Z7-20 에서 리눅스 부팅 및 AI 환경 설정
   * 이론: PetaLinux 빌드 플로우, rootfs 구성, ONNX Runtime 개요
   * 실습:
      * design_1_wrapper.xsa → PetaLinux 프로젝트 생성
      * UART 콘솔 로그인 → Python + ONNX Runtime 설치
      * ARM 기반 AI 추론 테스트 (예: MNIST MLP 모델)

### 🎥 5 주차 — 영상 및 센서 AI 실습
   * 목표: HDMI 입력 영상 → FPGA 가속 → HDMI 출력
   * 이론: VGA/HDMI 프로토콜, 프레임버퍼, DMA 전송
   * 실습:
      * HDMI In/Out 테스트 패턴 표시
      * FPGA Sobel 또는 Gaussian 필터 가속 적용
      * PS 측 OpenCV + ONNX Tiny-YOLO 추론 결합

### 🧩 6 주차 — 프로젝트 캡스톤 (Edge AI System)
   * 목표: AI + FPGA 통합 프로젝트 완성
   * 프로젝트 예시:
   * 카메라 영상 → FPGA 필터 → ONNX 모델 → 객체 분류
   * 오디오 입력 → FFT + CNN → 소리 감정 분류
   * 온도/조도 센서 데이터 → AI 예측 및 디스플레이
   * 결과물:
      * 프로젝트 레포트 (PDF + 회로도 + 코드)

발표 PPT + 동작 데모 영상

