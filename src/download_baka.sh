#!/bin/bash

# 引数のチェックとデフォルト値の設定
if [ $# -eq 0 ]; then
  echo "Usage: $0 youtube_url [seconds_to_trim]"
  exit 1
fi

# YouTubeのURLは必須
youtube_url=$1

# seconds_to_trimのデフォルト値を設定
# 引数が指定されていない場合は185を使用
seconds_to_trim=${2:-185}

# yt-dlpで使用する出力テンプレートを定義
output_template="伊集院光_深夜の馬鹿力_%(upload_date>%Y年%m月%d日)s.%(ext)s"

# yt-dlpで音声ファイルをダウンロードし、ファイル名を取得
echo "Downloading audio from YouTube..."
input_file=$(yt-dlp --quiet --print after_move:filepath --add-metadata --audio-format m4a -x -o "$output_template" "$youtube_url" --cookies-from-browser safari)

# 出力ファイル名を作成（接尾語として _trimmed を付ける）
output_file="${input_file%.*}_trimmed.m4a"

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

# トリミング後のファイル名を元のファイル名に戻す
mv "$output_file" "$input_file"
echo "File renamed to: $input_file"

# 終了メッセージ
echo "File trimmed and renamed successfully: $input_file"
