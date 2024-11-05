#!/bin/bash

# 引数のチェック
if [ $# -eq 0 ]; then
  echo "Usage: $0 youtube_url [seconds_to_trim]"
  exit 1
fi

# YouTubeのURLは必須
youtube_url=$1

# yt-dlpで使用する出力テンプレートを定義
output_template="%(title)s.%(ext)s"

# yt-dlpで音声ファイルをダウンロードし、オリジナルのファイル名を取得
echo "Downloading audio from YouTube..."
original_file=$(yt-dlp --quiet --console-title --print after_move:filepath --add-metadata --audio-format m4a -x -o "$output_template" "$youtube_url" --cookies-from-browser safari)

# スペースを含むファイル名を_に置換した新しいファイル名を作成
input_file=$(echo "$original_file" | sed 's/[[:space:]]/_/g' | sed 's/　/_/g')

# ファイルをリネーム
if [ "$original_file" != "$input_file" ]; then
    mv "$original_file" "$input_file"
    echo "Renamed file to: $input_file"
fi

# seconds_to_trimが指定されている場合のみトリム処理を実行
if [ $# -eq 2 ]; then
    # 推奨：185秒
    seconds_to_trim=$2
    
    # 出力ファイル名を作成（接尾語として _trimmed を付ける）
    output_file="${input_file%.*}_trimmed.m4a"

    # 音声ファイルの総時間を取得 (秒単位)
    duration=$(ffprobe -v quiet -select_streams a:0 -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")

    # duration が空の場合のエラーチェック
    if [ -z "$duration" ]; then
        echo "Error: Could not determine file duration. File may not exist or be corrupted."
        echo "Input file path: $input_file"
        echo "Original file path: $original_file"
        exit 1
    fi

    # 総時間を確認用に出力
    echo "Total duration: $duration seconds"

    # カット後の時間を計算（bcコマンドで小数点以下の計算を行う）
    new_length=$(echo "$duration - $seconds_to_trim" | bc -l)

    # 確認用に出力
    echo "New length will be: $new_length seconds"

    # 時間が0未満にならないようチェック
    if (( $(echo "$new_length < 0" | bc -l) )); then
        echo "Error: seconds_to_trim ($seconds_to_trim) is greater than the total length of the file ($duration seconds)."
        exit 1
    fi

    # FFmpegを使用してファイルをトリミング
    ffmpeg -hide_banner -loglevel error -i "$input_file" -t "$new_length" -acodec copy "$output_file"

    # 元ファイルを削除
    rm "$input_file"
    echo "Original file deleted: $input_file"

    # トリミング後のファイル名を元のファイル名に戻す
    mv "$output_file" "$input_file"
    echo "File trimmed and renamed successfully: $input_file"
else
    echo "No trimming requested. Download completed: $input_file"
fi