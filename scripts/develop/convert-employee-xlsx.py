#!/usr/bin/env python3
"""
Excel組織構成データ → 社員マスタCSV 変換スクリプト

データソース: a_project/refs/データ3_(2026.02.02).xlsx
出力形式:     scripts/test_employees.csv と同一列定義（22列）

使い方:
  # 全件変換（本番用）
  python3 scripts/develop/convert-employee-xlsx.py

  # テスト用（先頭N件のみ）
  python3 scripts/develop/convert-employee-xlsx.py --limit 10

  # 出力先指定
  python3 scripts/develop/convert-employee-xlsx.py -o scripts/prod_employees.csv
"""

import argparse
import csv
import sys
from pathlib import Path

try:
    import openpyxl
except ImportError:
    print("エラー: openpyxl が必要です。 pip3 install openpyxl で導入してください。", file=sys.stderr)
    sys.exit(1)

# プロジェクトルートからの相対パス
DEFAULT_INPUT = "a_project/refs/データ3_(2026.02.02).xlsx"
DEFAULT_OUTPUT = "scripts/prod_employees.csv"
SHEET_NAME = "データ3"

# Excel列インデックス（0始まり）
COL = {
    "ID": 0,
    "Office": 2,        # 在籍事業所略称
    "SonyID": 4,         # SonyID → GID
    "Name": 6,           # 社内呼称 → EmployeeName
    "EmpType": 8,        # 社員区分 → EmployeeType
    "Position": 13,      # 職位 → Position
    "Division": 17,      # 部門 → Division
    "Bu": 18,            # 部 → Bu
    "Section": 19,       # 課 → Section
    "Unit": 20,          # 係 → Unit（今回データは空）
    "CostUnit": 21,      # 原価単位 → CostUnit
    "Email": 22,         # mail address → Email
    "DeptHeadGID": 25,   # 部門長SonyID
    "DeptHeadName": 26,  # 部門長氏名
    "IsDeptHead": 27,    # 部門長本人フラグ（1 or None）
    "DirectorGID": 28,   # 部長SonyID
    "DirectorName": 29,  # 部長氏名
    "IsDirector": 30,    # 部長本人フラグ（1 or None）
    "ManagerGID": 31,    # 課長SonyID
    "ManagerName": 32,   # 課長氏名
    "IsManager": 33,     # 課長本人フラグ（1 or None）
}

CSV_HEADERS = [
    "GID", "EmployeeName", "Email", "Office", "EmployeeType", "Position",
    "IsManagement", "CostUnit", "Department", "Division", "Bu", "Section",
    "DeptHeadGID", "DeptHeadName", "IsDeptHead",
    "DirectorGID", "DirectorName", "IsDirector",
    "ManagerGID", "ManagerName", "IsManager",
    "IsActive",
]


def safe_str(val):
    """None → 空文字、全角スペースを半角に置換"""
    if val is None:
        return ""
    return str(val).replace("\u3000", " ").strip()


def flag_to_bool(val):
    """Excel本人フラグ（1 or None）→ True/False"""
    return "True" if val == 1 else "False"


def convert_row(row):
    """Excelの1行 → CSV辞書"""
    is_manager = row[COL["IsManager"]] == 1
    is_director = row[COL["IsDirector"]] == 1

    return {
        "GID": safe_str(row[COL["SonyID"]]),
        "EmployeeName": safe_str(row[COL["Name"]]),
        "Email": safe_str(row[COL["Email"]]),
        "Office": safe_str(row[COL["Office"]]),
        "EmployeeType": safe_str(row[COL["EmpType"]]),
        "Position": safe_str(row[COL["Position"]]),
        "IsManagement": "True" if (is_manager or is_director) else "False",
        "CostUnit": safe_str(row[COL["CostUnit"]]),
        "Department": safe_str(row[COL["Office"]]),  # Department = 在籍事業所略称
        "Division": safe_str(row[COL["Division"]]),
        "Bu": safe_str(row[COL["Bu"]]),
        "Section": safe_str(row[COL["Section"]]),
        "DeptHeadGID": safe_str(row[COL["DeptHeadGID"]]),
        "DeptHeadName": safe_str(row[COL["DeptHeadName"]]),
        "IsDeptHead": flag_to_bool(row[COL["IsDeptHead"]]),
        "DirectorGID": safe_str(row[COL["DirectorGID"]]),
        "DirectorName": safe_str(row[COL["DirectorName"]]),
        "IsDirector": flag_to_bool(row[COL["IsDirector"]]),
        "ManagerGID": safe_str(row[COL["ManagerGID"]]),
        "ManagerName": safe_str(row[COL["ManagerName"]]),
        "IsManager": flag_to_bool(row[COL["IsManager"]]),
        "IsActive": "True",
    }


def main():
    parser = argparse.ArgumentParser(description="Excel組織構成 → 社員マスタCSV変換")
    parser.add_argument("-i", "--input", default=DEFAULT_INPUT, help="入力Excelファイルパス")
    parser.add_argument("-o", "--output", default=DEFAULT_OUTPUT, help="出力CSVファイルパス")
    parser.add_argument("--limit", type=int, default=0, help="変換件数上限（0=全件）")
    args = parser.parse_args()

    input_path = Path(args.input)
    if not input_path.exists():
        print(f"エラー: 入力ファイルが見つかりません: {input_path}", file=sys.stderr)
        sys.exit(1)

    print(f"読み込み中: {input_path}")
    wb = openpyxl.load_workbook(str(input_path), data_only=True, read_only=True)
    ws = wb[SHEET_NAME]

    rows = []
    for i, row in enumerate(ws.iter_rows(min_row=3, values_only=True)):
        if row[COL["ID"]] is None:
            continue
        rows.append(convert_row(row))
        if args.limit > 0 and len(rows) >= args.limit:
            break

    wb.close()

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_HEADERS)
        writer.writeheader()
        writer.writerows(rows)

    print(f"変換完了: {len(rows)} 件 → {output_path}")

    # サマリー表示
    mgmt_count = sum(1 for r in rows if r["IsManagement"] == "True")
    print(f"  管理職: {mgmt_count} 名 / 一般: {len(rows) - mgmt_count} 名")


if __name__ == "__main__":
    main()
