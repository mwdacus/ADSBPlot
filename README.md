# ADSBPlot
Plots ADS-B Data into the MATLAB GUI Interface, `ADSB_Main_Plot`. Included figure types are:
  - Altitude vs. Latitude and Longitude, respectively: `plot_2D_LonAlt.m` and `plot_2D_LonAlt.m`
  - 2D Topographic Plot: `plottopo.m`
  - 3D Aerial Plot: `plot_3D.m`
  - Animation of Selected Data: `plot_flightanim.m`
  - Groundspeed and Altitude of Selected Aircraft: `plot_speed.m`

## Filtering Methods
### Markers
Figures are color-coded based on user selection within the User Interface. The main marker choices are 1)Navigational Integrity Category (NIC) Value, 2) ICAO Number, or 3) NIC Value threshold that implies some form of interference. If the NIC value of an ADS-B message/position is below a value of 7 (possible intererence), the position fix will indicate with a red marker, otherwise, the position fix will be indicated with a green marker.

### Min/Max NIC Value
ADS-B data is also filtered by determining the NIC value threshold viewable from the Figures. NIC values range from 0-11.

### Time Window
To adjust the static time window of all the figures, simply go the tab subsection on the GUI interface 'Time Window' and select the desired starting and closing hour on the ADS-B data. 

## Installation
To install the `+ADSBtools` helper functions, add the [`ADSBtools`](https://github.com/liu1322/ADSBtools) Github Repository, and add it to your existing path using the MATLAB command, `addpath()`.

To use GUI interface `ADSB_Main_Plot`, open `ADSB_Main_Plot.mlapp` in MATLAB click 'Run.' To upload ADS-B data, click 'Upload Files' in the top left corner of the window. You can select one or multiple files before closing the window. The uploaded data must be either the raw Position ADS-B message, or a State Vector (SV) report (which contain at least lat, lon, or alt). If the uploaded data does not contain NIC values, then it will default to the ICAO number, and will not allow the user to 

(Insert Picture of Interface)

## Export 
### Filtered File

### Video
