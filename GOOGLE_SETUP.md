# 구글 드라이브 · 시트 실시간 연동 설정 가이드

앱의 상단 메뉴(⋮) → **구글 드라이브 연동** 에서 내 구글 드라이브의 모든
스프레드시트를 실시간으로 불러올 수 있습니다. 최초 1회 아래 설정으로 발급한
**OAuth 클라이언트 ID** 를 앱에 입력하면 됩니다. (클라이언트 ID는 브라우저에만
저장되며 코드/서버에 저장되지 않습니다.)

## 동작 방식

- 브라우저의 Google Identity Services 팝업으로 로그인·동의를 받습니다.
- 발급받은 액세스 토큰으로 아래 두 API를 **읽기 전용**으로 호출합니다.
  - Google Drive API — 스프레드시트 목록 조회 (`drive.metadata.readonly`)
  - Google Sheets API — 탭/셀 값 조회 (`spreadsheets.readonly`)
- 별도의 백엔드 서버나 클라이언트 시크릿이 필요 없습니다.

## 클라이언트 ID 발급 (5단계)

1. **API 사용 설정** — [Google Cloud Console](https://console.cloud.google.com/)
   → API 및 서비스 → 라이브러리에서 다음을 각각 "사용 설정":
   - Google Drive API
   - Google Sheets API
2. **OAuth 동의 화면** — API 및 서비스 → OAuth 동의 화면
   - User Type: 외부(External) 선택 후 생성
   - 앱 정보를 채우고, **테스트 사용자**에 본인 구글 계정을 추가
     (테스트 모드에서는 등록된 계정만 로그인할 수 있습니다.)
3. **사용자 인증 정보 생성** — 사용자 인증 정보 → 사용자 인증 정보 만들기 →
   OAuth 클라이언트 ID → 애플리케이션 유형: **웹 애플리케이션**
4. **승인된 JavaScript 원본**에 앱을 여는 주소를 추가:
   - 배포(GitHub Pages) 주소: `https://<사용자>.github.io`
   - 로컬 개발: `http://localhost` 그리고 `http://localhost:<포트>`
     (예: `flutter run -d chrome` 사용 포트)
   - ⚠️ 리디렉션 URI는 필요 없습니다(토큰 팝업 방식). JavaScript 원본만 정확히
     넣어주세요. 경로/슬래시 없이 스킴+호스트(+포트)만 입력합니다.
5. 생성된 **클라이언트 ID**(`...apps.googleusercontent.com`)를 복사해 앱의
   "구글 드라이브 연동" 화면 입력칸에 붙여넣고 **구글 계정으로 연결**을 누릅니다.

## 자주 겪는 오류

| 증상 | 원인/해결 |
| --- | --- |
| 팝업이 바로 닫히고 오류 | 승인된 JavaScript 원본에 현재 주소가 없음 → 4단계 확인 |
| `403 access_denied` | 테스트 사용자에 로그인 계정이 없음 → 2단계 확인 |
| `GIS_NOT_LOADED` | 광고 차단기 등이 `accounts.google.com/gsi/client` 차단 |
| 목록이 비어 있음 | 해당 계정에 스프레드시트가 없거나 다른 계정으로 로그인함 |

## 배포 반영

`web/index.html` 과 Dart 코드가 바뀌었으므로, 배포 사이트에 반영하려면 다시
빌드해야 합니다.

```bash
flutter pub get
flutter build web --base-href /HBG-OT/
# 산출물(build/web)을 docs/ 로 복사해 GitHub Pages에 배포
```
