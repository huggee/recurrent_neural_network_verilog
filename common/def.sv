`define DEFMACRO


/******************************************************/
`define N_IN  1    // 入力層のニューロン数
`define N_H   30     // 隠れ層のニューロン数
`define N_OUT 1    // 出力層のニューロン数
/******************************************************/
`define TIMESTEP    4
`define R_TIMESTEP  0 : `TIMESTEP-1

`define N_SHIFT 3    // 学習率　2のマイナス(N_SHIFT)乗

`timescale 1ns/1ps
`define CLOCK_PERIOD 100

`define W_ADDR      10
`define W_DATA      8
`define W_DELTA     20
`define W_NEURON    12
`define W_SRAM_ADDR 17
`define W_WEIGHT    16

`define R_ADDR      `W_ADDR-1      : 0
`define R_DATA      `W_DATA-1      : 0
`define R_DELTA     `W_DELTA-1     : 0
`define R_NEURON    `W_NEURON-1    : 0
`define R_SRAM_ADDR `W_SRAM_ADDR-1 : 0
`define R_WEIGHT    `W_WEIGHT-1    : 0


`define N_WI (`N_IN + 1) * `N_H
`define N_WH (`N_H + 1) * `N_H
`define N_WO (`N_H + 1) * `N_OUT

// SRAMのアドレス定義
`define ADDR_WI_START     17'h0                   // 入力-隠れ層の重み開始アドレス
`define ADDR_WH_START     `ADDR_WI_START + `N_WI  // 隠れ-隠れ層の重み開始アドレス
`define ADDR_WO_START     `ADDR_WH_START + `N_WH  // 隠れ-出力層の重み開始アドレス
`define ADDR_INPUT_START  `ADDR_WO_START + `N_WO  // 入力データ開始アドレス
`define ADDR_LABEL_START  `ADDR_INPUT_START + `N_IN  // 入力データ開始アドレス
`define ADDR_OUTPUT_START `ADDR_LABEL_START + `N_OUT  // 出力結果の開始アドレス

`define ADDR_WI_END     `ADDR_WH_START - 1     // 入力-隠れ重み終了アドレス
`define ADDR_WH_END     `ADDR_WO_START - 1     // 隠れ-隠れ重み終了アドレス
`define ADDR_WO_END     `ADDR_INPUT_START - 1  // 隠れ-出力層の重み終了アドレス
`define ADDR_INPUT_END  `ADDR_LABEL_START - 1  // 入力データ終了アドレス
`define ADDR_LABEL_END  `ADDR_OUTPUT_START - 1 // 入力データ終了アドレス
`define ADDR_OUTPUT_END `ADDR_OUTPUT_START + `N_OUT - 1 // 出力結果の終了アドレス

`define ADDR_DEBUG_H_START `ADDR_OUTPUT_START + `N_OUT
`define ADDR_DEBUG_Y_START `ADDR_DEBUG_H_START + `N_H
`define ADDR_END           `ADDR_DEBUG_Y_START + `N_OUT

`define ADDR_DEBUG_H_END   `ADDR_DEBUG_Y_START - 1
`define ADDR_DEBUG_Y_END   `ADDR_END - 1
