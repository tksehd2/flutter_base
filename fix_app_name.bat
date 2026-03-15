@echo off
:: 한글 깨짐 방지
chcp 65001 > nul

echo ==================================================
echo               앱 이름 변경 스크립트
echo ==================================================
echo.

echo [1/2] rename 패키지를 다운로드 및 활성화합니다...
call dart pub global activate rename
echo.

set /p APP_NAME="[2/2] 새로운 앱 이름을 입력하세요: "
echo.

echo [%APP_NAME%] (으)로 앱 이름을 변경 중입니다...
call dart pub global run rename setAppName --targets ios,android --value "%APP_NAME%"

echo.
echo 변경 작업이 완료되었습니다!
pause