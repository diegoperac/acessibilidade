%% Ajuste de velocidade por cores kawaii is justice
%Para escolher a velocidade mostre apenas uma obj vermelho e para enviar a velocidade pro lego mostre 2
%A velocidade é proporcinal a posição na vertical do obj vermelho


%cameras = imaqhwinfo;
%cameras.InstalledAdaptors
clear all
clc

%%Descomente td abaixo disso para funcionar com o lego

%% Cria a conexão com o lego 
%COM_CloseNXT all
%h = COM_OpenNXT('bluetooth.ini');
%COM_SetDefaultNXT(h);                    
%NXT_PlayTone(440, 500);

%MotorA = NXTMotor('A');
%MotorB = NXTMotor('B');
%MotorC = NXTMotor('C');
%MotorBC = NXTMotor('BC')

%Descomente td abaixo disso para funcionar com o lego

%% Ajusta a sensibilidade do reconenhcimento
redThresh = 0.01;

% Configura a camera (Para webcam de notebook as configurações normalmente são essas msm) 

vidDevice = imaq.VideoDevice('winvideo',1); 
vidDevice.VideoFormat = 'YUY2_640x480';
vidDevice.ROI = [1 1 640 480];
vidDevice.ReturnedColorSpace  = 'rgb';

vidInfo = imaqhwinfo(vidDevice); 

%preview(vidDevice)

%% Configura os parametros de visão 
hblob = vision.BlobAnalysis;
hblob.AreaOutputPort = false; 
hblob.CentroidOutputPort = true;
hblob.BoundingBoxOutputPort = true; 
hblob.MinimumBlobArea = 600; % Area minima a ser detectada
hblob.MaximumBlobArea = 3000; % Area maxima a ser detectada
hblob.MaximumCount = 10; % Numero maximo de pontos a ser reconhecidos

%% Cria um quadrado em volta dos pontos detectados
 
hshapeinsRedBox = vision.ShapeInserter;
%hshapeinsRedBox.Shape = 'Circles'
hshapeinsRedBox.BorderColor = 'Custom';
hshapeinsRedBox.CustomBorderColor = [1 0 0]; 
hshapeinsRedBox.Fill = true;
hshapeinsRedBox.FillColor = 'Custom';
hshapeinsRedBox.CustomFillColor = [1 0 0];
hshapeinsRedBox.Opacity = 0.4;

%% Não sei explicar direito mas não é muito util
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
illya=0;

%% Isso foi o Bruno q fez ( aqui q acontece o importante )

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

   %% Isso fui eu q fiz mas não lembro direito oq faz
    % So sei q faz uma regra de 3 pra definir a velocidade


  if set ~ [];
     cordy(nFrame,1)=set(1,2);
     nfra=cordy(nFrame,1);
 
     cordypor1(nFrame,1)=(100-((100*nfra)/480));
     cordypor(nFrame,1)=round(cordypor1(nFrame,1));
         object;

     if object == 2 && illya==0;
         %% %%Descomente td abaixo disso para funcionar com o lego

         %MotorBC.Power = cordypor(nFrame,1);
         %MotorBC.SendToNXT();
         
         %Descomente td acima disso para funcionar com o lego

         fprintf('\n Velocidade em %d porcento',cordypor(nFrame,1))
         illya=0;
     elseif object == 1;
         illya=0;
     %else 
        % illya=1
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
