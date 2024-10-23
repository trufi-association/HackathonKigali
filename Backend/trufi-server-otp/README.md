## INTRODUCTION 

**Trufi’s Open Trip Planner (OTP) Server** tool allows you to view routes in your area using/based on the PBF and GTFS files you create. All required dependencies are included. 


## IMPORTANT INFORMATION

To use this tool, you need to create a GTFS file. You can learn how to use our [GTFS tool here](https://github.com/trufi-association/trufi-gtfs-builder/blob/main/README.md).

To properly work, OTP requires a GTFS file and a location. In addition to a GTFS file, here is a brief overview of the tools you will use: Geofabrik, Docker, Boundingbox, and Open Trip Planner.

Geofabrik is a map of the world that you can view and extract sub-regions from.   

Boundingbox is a tool that allows users to select certain geographical areas and coordinates to create maps and sub-regions. 

Docker describes itself as an open platform for developing, shipping, and running applications.

Open Trip Planner (OTP) describes itself as a family of open-source software projects that provides passenger information and transportation network analysis services.


### STEPS

+ **Step 1**: Download [Trufi’s Open Trip Planner Server tool]( https://github.com/trufi-association/trufi-server-otp).

+ **Step 2**: Clone the [tool](gh repo clone trufi-association/trufi-server-otp) 

+ **Step 3**: Download [Docker]( https://www.docker.com/) and [Bounding Box]( https://boundingbox.klokantech.com/).
 
+ **Step 4**: Navigate to your editor. Open it. Paste the Trufi folder inside the new project.

+ **Step 5**: Paste your GTFS file inside your project.

+ **Step 6**: Copy and paste GTFS and PBF files into the Docker compose file.

+ **Step 7**: To run our tool, open the Docker README file and follow the instructions to run the command in the editor.
  
+ **Step 8**: To run our OTP Server tool, open the README and run the command in the editor.

+ **Step 9**: Choose what version of the program you want to run. 

+ **Step 10**: Run comments in the terminal.

+ **Step 11**: To check whether or not Docker is running type _Docker ps_ in the terminal.

 **Note**: if the program is running and there are errors, this is likely where you will see them.


### Optional Step
 
To view your project, open a port. 
- [ ] Remove the slash(es) after the ports comment and open a localhost url using the port number listed. 

