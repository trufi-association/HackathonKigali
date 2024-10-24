
# Flutter Project Setup

## Prerequisites

To get started with this Flutter project, ensure that the necessary environment is set up:

- Git (https://git-scm.com/downloads)
- Docker (https://www.docker.com/products/docker-desktop/)
- Flutter SDK (https://flutter.dev/docs/get-started/install)
- Visual Studio Code (This is the editor used for this documentation)

## Cloning the Repository

Once your environment is ready, clone the project repository by running the following command:

```bash
git clone https://github.com/trufi-association/HackathonKigali.git
```


## Optional: Running Backend Services Locally

If you want to run the backend services (Photon and OTP) locally using Docker, you can use Docker Compose.
### Run OTP
[OTP Documentation](https://docs.opentripplanner.org/en/v2.4.0/)
   ```bash
   cd Backend/trufi-server-otp
   docker compose compose up -d
   ```

### Run Photon
   ```bash
   cd Backend/trufi-server-photon
   docker compose compose up -d
   ```
### Run NGINX

   ```bash
   cd Backend/
   docker compose compose up -d
   ```


## Running the Application

1. Open a terminal and navigate to the project directory:

   ```bash
   cd Frontend/kigali_mobility
   ```

2. Install the necessary dependencies by running the following command:

   ```bash
   flutter pub get
   ```

3. Once the dependencies are installed, ensure that a physical device is connected or that an emulator is running.

4. To run the application, either press `F5` in **Visual Studio Code** or use the following command in the terminal:

   ```bash
   flutter run
   ```

By following these steps, your Flutter application should be running successfully on a connected device or emulator.

### Server Configuration

By default, the application is configured to use the **OTP-Kigali** servers. However, if you want to override the services and use your own local servers for **Photon** and **OTP**, follow these steps:

1. Go to the directory where the `main.dart` file is located:

   ```bash
   cd Frontend/kigali_mobility/lib
   ```

2. Open the `main.dart` file and locate the following commented code:

   ```dart
   // Configure endpoints
   // ApiConfig().openTripPlannerUrl = "";
   // ApiConfig().searchPhotonEndpoint = "";
   // ApiConfig().reverseGeodecodingPhotonEndpoint = "";
   ```

3. Uncomment the lines and replace the URLs with your own local server endpoints.

By doing this, your application will now interact with your local services for Photon and OTP instead of the default OTP-Kigali servers.

## Logs from Cochabamba-Bolivia

(Cochabamba-Bolivia-logs)[https://drive.google.com/drive/folders/1wjXc4zviwOaw7gVwGlQyeM3eXeUiigT2?usp=sharing]