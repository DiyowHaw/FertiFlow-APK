"""
FertiFlow - YOLOv8 Training Script
===================================
Panduan lengkap untuk melatih ulang model deteksi penyakit daun cabai.

REQUIREMENTS:
    pip install ultralytics roboflow opencv-python pillow pyyaml

STRUKTUR DATASET YANG DIBUTUHKAN:
    dataset/
    ├── images/
    │   ├── train/    (gambar training ~70%)
    │   ├── val/      (gambar validasi ~20%)
    │   └── test/     (gambar testing  ~10%)
    └── labels/
        ├── train/    (file .txt format YOLO)
        ├── val/
        └── test/

CLASS IDs:
    0 = Sehat
    1 = Leaf Curl       (Keriting Daun)
    2 = Leaf Spot       (Bercak Daun)
    3 = Yellowish Leaf  (Daun Menguning)
    4 = Embun Tepung    (Powdery Mildew)
    5 = Serangan Hama

REKOMENDASI JUMLAH DATA:
    - Minimum : 200 gambar per kelas
    - Optimal  : 500-1000 gambar per kelas
"""

import os, shutil, yaml
from pathlib import Path
from ultralytics import YOLO

PROJECT_NAME = "fertiflow_chili"
MODEL_BASE   = "yolov8n.pt"
EPOCHS       = 100
IMAGE_SIZE   = 640
BATCH_SIZE   = 16
DEVICE       = "0"
DATASET_DIR  = "./dataset"
OUTPUT_DIR   = "./runs"
EXPORT_PATH  = "../assets/models/best.tflite"

CLASS_NAMES = [
    "Sehat", "Leaf Curl", "Leaf Spot",
    "Yellowish Leaf", "Embun Tepung", "Serangan Hama",
]

def create_dataset_yaml():
    config = {
        "path":  str(Path(DATASET_DIR).resolve()),
        "train": "images/train",
        "val":   "images/val",
        "test":  "images/test",
        "nc":    len(CLASS_NAMES),
        "names": CLASS_NAMES,
    }
    with open("fertiflow_dataset.yaml", "w") as f:
        yaml.dump(config, f, allow_unicode=True, default_flow_style=False)
    return "fertiflow_dataset.yaml"

def train():
    yaml_path = create_dataset_yaml()
    model = YOLO(MODEL_BASE)
    results = model.train(
        data=yaml_path, epochs=EPOCHS, imgsz=IMAGE_SIZE,
        batch=BATCH_SIZE, device=DEVICE,
        project=OUTPUT_DIR, name=PROJECT_NAME, exist_ok=True,
        optimizer="AdamW", lr0=0.001, lrf=0.01,
        momentum=0.937, weight_decay=0.0005, warmup_epochs=3.0,
        hsv_h=0.015, hsv_s=0.7, hsv_v=0.4,
        degrees=10.0, translate=0.1, scale=0.5,
        fliplr=0.5, mosaic=1.0, mixup=0.1, copy_paste=0.1,
        dropout=0.1, label_smoothing=0.1, patience=20,
        save=True, save_period=10,
    )
    print(f"Best model: {results.save_dir}/weights/best.pt")
    return results

def export_to_tflite(model_path=None):
    if model_path is None:
        model_path = f"{OUTPUT_DIR}/{PROJECT_NAME}/weights/best.pt"
    model = YOLO(model_path)
    model.export(format="tflite", imgsz=640, int8=True, data="fertiflow_dataset.yaml")
    tflite_files = list(Path(model_path).parent.glob("*.tflite"))
    if tflite_files:
        dst = Path(EXPORT_PATH)
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(tflite_files[0], dst)
        print(f"TFLite disalin ke: {dst}")

def validate(model_path=None):
    if model_path is None:
        model_path = f"{OUTPUT_DIR}/{PROJECT_NAME}/weights/best.pt"
    model = YOLO(model_path)
    metrics = model.val(data="fertiflow_dataset.yaml")
    print(f"mAP50={metrics.box.map50:.4f}  mAP50-95={metrics.box.map:.4f}")
    print(f"Precision={metrics.box.mp:.4f}  Recall={metrics.box.mr:.4f}")

if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("--mode", choices=["train","export","validate","all"], default="all")
    p.add_argument("--model", default=None)
    args = p.parse_args()
    if args.mode in ("train","all"):   train()
    if args.mode in ("export","all"):  export_to_tflite(args.model)
    if args.mode in ("validate","all"): validate(args.model)
