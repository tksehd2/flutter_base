@echo off
:: 한글 깨짐 방지
chcp 65001 > nul

echo ==================================================
echo             패키지명(Bundle ID) 변경 스크립트
echo ==================================================
echo.

echo [1/2] rename 패키지를 다운로드 및 활성화합니다...
call dart pub global activate rename
echo.

set /p BUNDLE_ID="[2/2] 새로운 패키지명을 입력하세요 (예: com.example.app): "
echo.

echo [%BUNDLE_ID%] (으)로 패키지명을 변경 중입니다...
call dart pub global run rename setBundleId --targets ios,android --value "%BUNDLE_ID%"

echo.
echo 변경 작업이 완료되었습니다!
pause