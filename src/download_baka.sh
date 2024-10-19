#!/bin/bash

# 引数のチェック
if [ $# -ne 2 ]; then
  echo "Usage: $0 youtube_url seconds_to_trim"
  exit 1
fi

# 引数を変数に割り当て
youtube_url=$1
seconds_to_trim=$2

# yt-dlp で音声ファイルをダウンロード (m4a形式で保存)
echo "Downloading audio from YouTube..."
yt-dlp --add-metadata --audio-format m4a -x "$youtube_url" --cookies-from-browser safari

# ダウンロードされたファイル名を取得（最新の .m4a ファイル）
input_file=$(ls -t *.m4a | head -n 1)

# ファイル名と拡張子を分離
basename="${input_file%.*}"

# 出力ファイル名を作成（接尾語として _trimmed を付ける）
output_file="${basename}_trimmed.m4a"

# 音声ファイルの総時間を取得 (HH:MM:SS形式)
duration=$(ffmpeg -i "$input_file" 2>&1 | grep "Duration" | awk '{print $2}' | tr -d ,)

# 総時間を秒に変換
total_seconds=$(echo "$duration" | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }')

# カット後の時間を計算
new_length=$(echo "$total_seconds - $seconds_to_trim" | bc)

# 時間が0未満にならないようチェック
if (( $(echo "$new_length < 0" | bc -l) )); then
  echo "Error: seconds_to_trim is greater than the total length of the file."
  exit 1
fi

# FFmpegを使用してファイルをトリミング
ffmpeg -i "$input_file" -t "$new_length" -acodec copy "$output_file"

# 元ファイルを削除
rm "$input_file"
echo "Original file deleted: $input_file"

# 出力ファイル名を新しいフォーマットに変更
# 元のファイル名のフォーマット: 伊集院光 深夜の馬鹿力 yyyy 年mm月dd日 [ランダムな文字列]_trimmed
# 新しいファイル名フォーマット: 伊集院光_深夜の馬鹿力_yyyy年mm月dd日.m4a
new_filename=$(echo "$output_file" | sed -E 's/伊集院光 深夜の馬鹿力 ([0-9]{4}) 年([0-9]{2})月([0-9]{2})日 .+_trimmed/伊集院光_深夜の馬鹿力_\1年\2月\3日/')

# ファイル名を変更
mv "$output_file" "$new_filename"
echo "File renamed to: $new_filename"

# 終了メッセージ
echo "File trimmed and renamed successfully: $new_filename"
