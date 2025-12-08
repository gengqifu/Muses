#!/usr/bin/env python3
"""
简易导出校验工具：验证 WAV/CSV/JSONL 与事件日志是否一致。

用法示例：
  python tools/validate_export.py --wav /path/to/prefix_pcm.wav \
    --csv /path/to/prefix_spectrum.csv \
    --jsonl /path/to/prefix_spectrum.jsonl \
    --events /path/to/prefix_events.jsonl

事件日志由导出时开启 debugEvents 写出，包含 pcm/spectrum 帧及 samples/bins。
"""
import argparse
import csv
import json
import math
import struct
import sys
from pathlib import Path


def read_wav_float32(path: Path):
    with path.open("rb") as f:
        data = f.read()
    if len(data) < 44 or data[:4] != b"RIFF" or data[8:12] != b"WAVE":
        raise ValueError("不是有效的 WAV 文件")
    data_bytes = data[44:]
    if len(data_bytes) % 4 != 0:
        raise ValueError("WAV data 长度不是 float32 对齐")
    return list(struct.unpack("<%sf" % (len(data_bytes) // 4), data_bytes))


def read_events(path: Path):
    pcm_events = []
    spec_events = []
    with path.open() as f:
        for line in f:
            if not line.strip():
                continue
            obj = json.loads(line)
            if obj.get("type") == "pcm":
                pcm_events.append(obj)
            elif obj.get("type") == "spectrum":
                spec_events.append(obj)
    return pcm_events, spec_events


def read_spectrum_csv(path: Path):
    rows = []
    with path.open() as f:
        reader = csv.reader(f)
        header = next(reader, None)
        for row in reader:
            rows.append(row)
    return header, rows


def read_spectrum_jsonl(path: Path):
    rows = []
    with path.open() as f:
        for line in f:
            if not line.strip():
                continue
            rows.append(json.loads(line))
    return rows


def assert_close(a, b, tol=1e-6):
    if isinstance(a, float) or isinstance(b, float):
        if math.isnan(a) and math.isnan(b):
            return
        if abs(a - b) > tol:
            raise AssertionError(f"值不一致: {a} vs {b}")
    else:
        if a != b:
            raise AssertionError(f"值不一致: {a} vs {b}")


def validate(args):
    pcm_events, spec_events = read_events(args.events) if args.events else ([], [])

    if args.wav and pcm_events:
        samples = read_wav_float32(args.wav)
        flat_events = [s for ev in pcm_events for s in ev["samples"]]
        if len(samples) != len(flat_events):
            raise AssertionError(f"WAV samples 数量不一致: {len(samples)} vs 事件 {len(flat_events)}")
        for a, b in zip(samples, flat_events):
          assert_close(a, b, tol=1e-4)

    if args.csv and spec_events:
        header, rows = read_spectrum_csv(args.csv)
        if len(rows) != len(spec_events):
            raise AssertionError(f"CSV 行数与事件不一致: {len(rows)} vs {len(spec_events)}")
        for row, ev in zip(rows, spec_events):
            seq = int(row[0])
            ts = int(row[1])
            bin_hz = float(row[2])
            assert_close(seq, ev["sequence"])
            assert_close(ts, ev["timestampMs"])
            assert_close(bin_hz, ev.get("binHz", 0.0), tol=1e-4)

    if args.jsonl and spec_events:
        rows = read_spectrum_jsonl(args.jsonl)
        if len(rows) != len(spec_events):
            raise AssertionError(f"JSONL 行数与事件不一致: {len(rows)} vs {len(spec_events)}")
        for row, ev in zip(rows, spec_events):
            assert_close(row["sequence"], ev["sequence"])
            assert_close(row["timestampMs"], ev["timestampMs"])
            assert_close(row.get("binHz", 0.0), ev.get("binHz", 0.0), tol=1e-4)
            if "bins" in row:
                if len(row["bins"]) != len(ev["bins"]):
                    raise AssertionError("JSONL bins 数量不一致")
                for a, b in zip(row["bins"], ev["bins"]):
                    assert_close(a, b, tol=1e-4)

    print("校验通过")


def main():
    parser = argparse.ArgumentParser(description="校验导出文件与事件日志一致性")
    parser.add_argument("--wav", type=Path, help="PCM WAV 文件路径")
    parser.add_argument("--csv", type=Path, help="谱 CSV 文件路径")
    parser.add_argument("--jsonl", type=Path, help="谱 JSONL 文件路径")
    parser.add_argument("--events", type=Path, help="事件日志 JSONL（由导出 debug 生成）")
    args = parser.parse_args()

    if not any([args.wav, args.csv, args.jsonl]):
        parser.error("需要至少指定一个导出文件")
    validate(args)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"校验失败: {e}", file=sys.stderr)
        sys.exit(1)
