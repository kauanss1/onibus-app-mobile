# 🚌 Ônibus Motorista - Rastreador Pro

Este é um aplicativo desenvolvido em **Flutter** projetado para motoristas de transporte público ou privado. O objetivo principal é o rastreamento geográfico em tempo real, garantindo que a localização seja enviada mesmo que o aplicativo seja fechado ou a tela seja desligada.

## ✨ Funcionalidades
- **Rastreio em Segundo Plano:** Utiliza `Foreground Service` para manter o GPS ativo sem interrupções pelo sistema Android.
- **Persistência de Estado:** Graças ao `Shared Preferences`, o app lembra qual placa estava selecionada e se o rastreio estava ativo ao ser reiniciado.
- **Notificações em Tempo Real:** Exibe uma notificação fixa para o motorista saber que o sistema está operando.
- **Integração HTTP:** Envia coordenadas (Latitude/Longitude) para um servidor remoto (Render) via JSON.
- **Interface Intuitiva:** Design focado na facilidade de uso para o motorista, com ícones grandes e feedback visual de conexão (Wi-Fi/GPS).

## 🛠️ Tecnologias Utilizadas
- [Flutter](https://flutter.dev) (Framework UI)
- [Geolocator](https://pub.dev/packages/geolocator) (Captura de GPS)
- [Flutter Background Service](https://pub.dev/packages/flutter_background_service) (Serviço de fundo)
- [Shared Preferences](https://pub.dev/packages/shared_preferences) (Armazenamento local)
- [Http](https://pub.dev/packages/http) (Comunicação com API)

## 🚀 Como rodar o projeto
1. Certifique-se de ter o Flutter instalado.
2. Clone o repositório.
3. Execute `flutter pub get` para instalar as dependências.
4. Conecte um dispositivo Android (recomendado API 21+).
5. Execute `flutter run`.

---
Desenvolvido para monitoramento de frotas em tempo real.