# ADSBPlot
Plots ADS-B Data into the MATLAB GUI Interface, `ADSB_Main_Plot`. Included figure types are:
  - Altitude vs. Latitude and Longitude, respectively: `plot_2D_LonAlt.m` and `plot_2D_LonAlt.m`
  - 2D Topographic Plot: `plottopo.m`
  - 3D Aerial Plot: `plot_3D.m`
  - Animation of Selected Data: `plot_flightanim.m`
  - Groundspeed and Altitude of Selected Aircraft: `plot_speed.m`

## Installation
To install the `+ADSBtools` helper functions, add the [`ADSBtools`](https://github.com/liu1322/ADSBtools) Github Repository, and add it to your existing path using the MATLAB command, `addpath()`.

To use GUI interface `ADSB_Main_Plot`, open `ADSB_Main_Plot.mlapp` in MATLAB click 'Run.' To upload ADS-B data, click `Upload Files` in the top left corner of the window. You can select one or multiple files before closing the window. The uploaded data must be either the raw Position ADS-B message, or a State Vector (SV) report (which contain at least {time,lat, lon, alt, and icao}). If the uploaded data does not contain NIC values, then it will default to the ICAO number, and will not allow the user to select NIC as the desired marker.

![My Image](ui_adsbplot.png)



## Filtering Methods
### Markers
Figures are color-coded based on user selection within the User Interface. The main marker choices are 1) Navigational Integrity Category (NIC) Value, 2) ICAO Number, or 3) NIC Value threshold that implies some form of interference. If the NIC value of an ADS-B message/position is below a value of 7 (possible intererence), the position fix will indicate with a red marker, otherwise, the position fix will be indicated with a green marker.

### Min/Max NIC Value
ADS-B data is also filtered by determining the NIC value threshold viewable from the Figures. NIC values range from 0-11.

### Time Window
To adjust the static time window of all the figures, simply go the tab subsection on the GUI interface `Time Window` and select the desired starting and closing hour on the ADS-B data. 

## Exporting Files
### Filtered Dataset
To save the filtered data created within the GUI interface, go to the `Export Filtered Information` tab. Edit the filename as desired, then click `Export File`. 

### Figures
To save any of the desired figures within the UI, go to the desired figure to be saved, and click the Save icon in the top right corner of the figure. From there, a pop-up window will allow the user to save the file accordingly.

### Video
To create a video of the filtered data within the GUI interface, go to the `Animation` tab. From there, specify the filename of the video. The user also has the ability to specify framerate, and whether to include a centroid location. If chosen, the user has the ability to select either a moving point location or a kernel density estimation. The movign point location is an average of all NIC=0 within each frame, while the kernel density estimation assigns weights to NIC values (highest weight being NIC=0) and plots a distribution of the centroid as a contour map.
