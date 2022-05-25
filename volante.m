%cameras = imaqhwinfo;
%cameras.InstalledAdaptors
clear all
clc

COM_CloseNXT all
h = COM_OpenNXT('bluetooth.ini');  % procurar por disp. USB em seguida por bluetooth
COM_SetDefaultNXT(h);                    % define handle global como padrão
NXT_PlayTone(440, 500);

MotorA = NXTMotor('A');
MotorB = NXTMotor('B');
MotorC = NXTMotor('C');
MotorBC = NXTMotor('BC')


redThresh = 0.15; % Threshold for red detection

vidDevice = imaq.VideoDevice('winvideo', 1);
vidDevice.VideoFormat = 'YUY2_640x480';
vidDevice.ROI = [1 1 640 480];
vidDevice.ReturnedColorSpace  = 'rgb';

vidInfo = imaqhwinfo(vidDevice); 

%preview(vidDevice)

hblob = vision.BlobAnalysis;
hblob.AreaOutputPort = false;
hblob.CentroidOutputPort = true;
hblob.BoundingBoxOutputPort = true; 
hblob.MinimumBlobArea = 600;
hblob.MaximumBlobArea = 3000;
hblob.MaximumCount = 10;


hshapeinsRedBox = vision.ShapeInserter;
%hshapeinsRedBox.Shape = 'Circles'
hshapeinsRedBox.BorderColor = 'Custom';
hshapeinsRedBox.CustomBorderColor = [1 0 0];
hshapeinsRedBox.Fill = true;
hshapeinsRedBox.FillColor = 'Custom';
hshapeinsRedBox.CustomFillColor = [1 0 0];
hshapeinsRedBox.Opacity = 0.4;

htextinsRed = vision.TextInserter;
htextinsRed.Text = 'Vermelho : %2d';
htextinsRed.Location = [5 2];
htextinsRed.Color = [1 0 0];
htextinsRed.Font = 'Courier New';
htextinsRed.FontSize = 14;

htextinsCent = vision.TextInserter;
htextinsCent.Text = '+ X:%4d, Y:%4d';
htextinsCent.LocationSource = 'Input port';
htextinsCent.Color = [0 1 1];
htextinsCent.Font = 'Courier New';
htextinsCent.FontSize = 14;

hVideoIn = vision.VideoPlayer;
hVideoIn.Name = 'Final Video';
hVideoIn.Position = [100 100 vidInfo.MaxWidth+20 vidInfo.MaxHeight+30];

nFrame = 0; % Frame number initialization
del=0;

while(nFrame < 5000)
    
    rgbFrame = step(vidDevice); % Adiquire um unico frame
    rgbFrame = flipdim(rgbFrame,2); % obtain the mirror image for displaying
    diffFrameRed = imsubtract(rgbFrame(:,:,1), rgb2gray(rgbFrame)); % Get red component of the image
    diffFrameRed = medfilt2(diffFrameRed, [3 3]); % Filter out the noise by using median filter
    binFrameRed = im2bw(diffFrameRed, redThresh); % Convert the image into binary image with the red objects as white
    
    [centroidRed, bboxRed] = step(hblob, binFrameRed); % Get the centroids and bounding boxes of the red blobs
    centroidRed = uint16(centroidRed); % Convert the centroids into Integer for further steps
       
    % rgbFrame(1:50,1:90,:) = 0; % put a black region on the output stream
    vidIn = step(hshapeinsRedBox, rgbFrame, bboxRed); % Instert the red box
    
    for object = 1:1:length(bboxRed(:,1)) % Write the corresponding centroids for red
        centXRed = centroidRed(object,1); centYRed = centroidRed(object,2);
        vidIn = step(htextinsCent, vidIn, [centXRed centYRed], [centXRed-6 centYRed-9]);
    end
    
    vidIn = step(htextinsRed, vidIn, uint8(length(bboxRed(:,1)))); % Count the number of red blobs
    step(hVideoIn, vidIn); % Output video stream
     
    nFrame = nFrame+1;
   set=centroidRed;
   set=double(set);
   
  if set ~ [];
     cordy(nFrame,1)=set(1,2);
     cordx(nFrame,1)=set(1,1);
     
     nfra=cordy(nFrame,1);
     nfrax1=cordx(nFrame,1);
     nfrax=320-nfrax1;
     
     cordypor1(nFrame,1)=(100-((100*nfra)/480));
     cordypor(nFrame,1)=round(cordypor1(nFrame,1));
     
     cordxpor1(nFrame,1)=(((100*nfrax)/640));
     cordxpor(nFrame,1)=round(cordxpor1(nFrame,1));
     object;
     BC=(100-(((cordxpor)/100)*cordypor(nFrame,1)));
     BC=round(BC);
     if cordxpor > 0;
         MotorB.Power = cordypor(nFrame,1);
         MotorC.Power = BC;
         MotorB.SendToNXT();
         MotorC.SendToNXT();
     elseif cordxpor < 0;
         MotorC.Power = cordypor(nFrame,1);
         MotorB.Power = BC;
         MotorB.SendToNXT();
         MotorC.SendToNXT();
     end
     end
     end
 
%% Clearing Memory
release(hVideoIn); % Release all memory and buffer used
release(vidDevice);
 MotorC.Stop('off');
 MotorB.Stop('off');
COM_CloseNXT all
clear all;

%clc;
