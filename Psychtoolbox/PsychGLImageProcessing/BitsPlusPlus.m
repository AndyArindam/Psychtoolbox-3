function [win, winRect] = BitsPlusPlus(cmd, arg, dummy, varargin)
% BitsPlusPlus(cmd [, arg1][, arg2, ...]) -- Psychtoolbox interface to
% Cambridge Research Systems Bits++ box for high precision stimulus
% output to analog displays via 14 bit video converters.
%
% This function is used to set up and interface with the Bits++ box of
% CRS. It is a Matlab wrapper around lower level GLSL Psychtoolbox
% functions. This function depends on graphics hardware that supports the
% Psychtoolbox imaging pipeline and framebuffers with more than 14 bit
% precision, i.e., 16 bpc fixed point framebuffers or floating point
% framebuffers. Have a look at the Psychtoolbox Wiki where you can find a
% list of graphics cards with the neccessary features.
%
% This function supersedes the old Matlab based Bits++ Toolbox, which
% essentially provides the same functionality on any graphics card, but is
% harder to use, much slower and not fully integrated into PTB, ie, you
% can't take full advantage of PTB's advanced drawing and image processing
% functions when using the old Bits++ toolbox.
%
% cmd - The command that BitsPlusPlus should execute. cmd can be any of
% the following:
%
%
% Load a linear identity mapping CLUT into Bits++ while running in Bits++
% mode:
%
% BitsPlusPlus('LoadIdentityClut', window);
%
% Will schedule update to an identity clut. Next invocation of
% Screen('Flip', window); will actually upload the identity clut into
% Bits++.
%
%
% Schedule a Bits++ DIO command for execution on next Screen('Flip'):
%
% BitsPlusPlus('DIOCommand', window, repetitions, mask, data, command [, xpos, ypos]);
%
% This will draw the proper T-Lock control codes at positions (xpos, ypos)
% for execution of the Bits++ DIO commands (mask, data, command).
%
% You can specify multiple codes at once: If mask, data, command, xpos and
% ypos are matrices or vectors with 'num' rows, then each of the 'num' rows
% defines one T-Lock code. If mask, command, xpos and ypos are scalars and
% data is a one row vector, then only the corresponding T-Lock line is
% drawn.
%
% For each DIO command:
% 'mask' must be a 8 bit integer value, 'command' must be a 8 bit integer
% value, whereas 'data' must be a a 248 element row vector of bytes. 
%
% Consult your Bits++ manual for explanation of the meaning of the values.
%
% xpos and ypos are optional: By default, the T-Lock code is drawn into the
% 3rd pixel row of the output image, so it can't collide with a potential
% T-Lock code for CLUT updates.
%
% The DIO command will become effective during the next flip command. The
% T-Lock code is drawn during 'repetitions' successive invocations of
% Screen('Flip'). If you set 'repetitions' to -1, then the code will be
% drawn until you stop it via a call to BitsPlusPlus('DIOCommandReset', window);
%
%
% Disable use of the DIO T-Lock code blitting:
%
% BitsPlusPlus('DIOCommandReset', window);
% Stops blitting of T-Lock command codes immediately. If you want to use
% them again, you have to respecify codes via the BitsPlusPlus('DIOCommand',...);
%
%
%
%
% Open a full-screen window on the Bits++ display as with
% Screen('OpenWindow', ...), perform all initialization:
%
% The following commands will execute Screen('OpenWindow') with all proper
% parameters, followed by Bits++ init routines. They are completely sufficient
% drop in replacements for Screen('OpenWindow'), accepting and returning
% exactly the same arguments that Screen() would do, adjusting all
% parameters to the constraints of the Bits++, if necessary.
%
% Activate Bits++ mode:
%
% [win, winRect] = BitsPlusPlus('OpenWindowBits++', screenid, ...);
%
% This will open an onscreen window on Bits++ screen 'screenid' with a
% standard 8 bits per color channel framebuffer. The gamma table of your
% graphics hardware will be loaded with an identity gamma table, so the
% T-Lock system of Bits++ works and Bits++ can accept commmands embedded
% into the stimulus images. Psychtoolbox will automatically embed a T-Lock
% control line into the top line of the display screen, which encodes the
% 256 entry, 14 bit per color channel CLUT to use for Bits++ display mode.
% You can change the Bits++ CLUT at any time via the standard PTB
% Screen('LoadNormalizedGammaTable', win, newclut, 2); command. The
% 'newclut' will get uploaded to the Bits++ at the next invocation of
% Screen('Flip') to allow updates of the CLUT synchronous to stimulus
% updates. 'newclut' has to be a 256 rows by 3 columns matrix with values
% in range 0.0 - 1.0: 0.0 is mapped to clut color value 0, 1.0 is mapped to
% the highest Bits++ output color value 16383.
%
% This mode works on any OpenGL graphics hardware.
%
%
% Activate Mono++ mode:
%
% [win, winRect] = BitsPlusPlus('OpenWindowMono++', screenid, ...);
%
% This will open an onscreen window on Bits++ screen 'screenid' for display
% of pure luminance (grayscale) images. The framebuffer has a resolution of
% 32 bit floating point precision by default: This means that pixel luminance
% values have to be specified as floating point numbers between 0.0 and
% 1.0. 0.0 maps to black (Output intensity 0 on Bits++ device). 1.0 maps to
% white (Maximum output intensity 16383 on Bits++ device). The intensity
% range between 0.0 and 1.0 is internally represented and processed by
% Psychtoolbox with a resolution 23 bits, i.e. over 8 million levels of
% luminance. The Bits++ can resolve this range to 14 bits, ie. 16384 levels
% of luminance during display. This mode is not compatible with the use of
% any gamma- or clut- tables. Both the graphics hardwares gamma table and
% the Bits++ internal clut are set to an identity mapping while this mode
% is active. Please read the notes below the Color++ section for graphics
% hardware requirements and other useful tips for use of Bits++.
%
% If you call this subfunction as 'OpenWindowMono++WithOverlay', the
% overlay plane of Bits++ gets enabled and an additional overlay window is
% created for drawing the image for that overlay plane.
%
% [overlaywin, overlaywinRect] = BitsPlusPlus('GetOverlayWindow', win);
% - Will return the handle to the 'overlaywin'dow associated with the
% onscreen luminance window:
%
%   'overlayWin' is the handle to the overlay window associated with the
%   overlay of onscreen window 'win'. The overlay window is a standard
%   offscreen window, so you can do anything with it that you would want to
%   do with offscreen windows. The only difference is that the window is a
%   pure index window: It only has one "color channel", which can be written
%   with color values between 0 and 255. Values 1 to 255 get mapped to the
%   corresponding color indices of the Bits++ overlay plane: A zero value is
%   transparent -- Content of the onscreen window is visible. Positive
%   non-zero color values map to the 255 indices available in overlay mode,
%   these get mapped by the Bits++ CLUT to colors. You can define the
%   mapping of indices to CLUT colors via the
%   Screen('LoadNormalizedGammaTable', win, clut, 2); command.
%
%   Updates of the overlay image are synchronized to Screen('Flip')
%   updates. If you draw into the overlay window, the changed overlay image
%   will become visible at Screen('Flip') time -- in sync with the changed
%   onscreen window content. The overlay plane is not automatically cleared
%   to background (or transparent) color after a flip, but its content
%   persists across flips. You need to clear it out manually via a
%   Screen('FillRect') command.
%
%
% Activate Color++ mode:
%
% [win, winRect] = BitsPlusPlus('OpenWindowColor++', screenid, ...);
%
% This will open an onscreen window on Bits++ screen 'screenid' for display
% of 14 bit per color component 42bpp color images. The framebuffer has
% a resolution of 32 bit floating point precision for each color component
% by default: This means that (Red, Green, Blue) color pixel component
% values have to be specified as floating point numbers between 0.0 and
% 1.0. 0.0 maps to minimum output intensity on Bits++ device for a channel.
% 1.0 maps to maximum output intensity 16383 on Bits++ device for a channel.
% The color intensity range between 0.0 and 1.0 is internally represented and
% processed by Psychtoolbox with an effective resolution of about 23 bits,
% i.e. over 8 million levels of color per color channel. The Bits++ can resolve
% this range to 14 bits, ie. 16384 levels of color during display. This mode
% is not compatible with the use of any gamma- or clut- tables. Both the graphics
% hardwares gamma table and the Bits++ internal clut are set to an identity
% mapping while this mode is active. Please read the notes below for graphics
% hardware requirements and other useful tips for use of Bits++.
%
%
% If you use Color++ mode, you must call
% BitsPlusPlus('SetColorConversionMode', mode); first to select the mode
% for sampling the framebuffer and converting into output color values. See
% the respective section of "help PsychImaging" for 'Color++' or
% 'EnableDataPixxC48Output' mode for the Bits+ or Datapixx device for an
% explanation of this mandatory parameter. The setting before 22nd
% September 2010 for all PTB-3 versions was 0 (==zero).
%
%
% Notes for both Mono++ and Color++ mode:
%
% In Mono++ and Color++ mode, PTB expects color values in the range 0.0 to
% 1.0 instead of the (otherwise usual) range 0 to 255. The range 0.0-1.0
% is a more natural fit for high dynamic range/precision output devices than
% the 0-255 range with its strong ties to 8 bpc output devices. 0-1 is also
% the "natural" native color range of OpenGL, so colors in this range can
% be handled by the graphics hardware at a higher speed. You can change the
% mapping of input colors to output intensities by use of the command
% Screen('ColorRange') (see its online help for usage), but in the interest
% of uniform code and to avoid possible side effects with some graphics
% hardware, we strongly recommend using the default 0.0-1.0 color range.
%
% You can still pass standard 8bpc (256 color/intensity levels) color/luminance
% textures to PTB via standard use of Screen('MakeTexture') - the hardware
% will convert such 8bpc images to OpenGL's native color range, as well as
% any images delivered by the Quicktime movie playback engine or the video
% capture engine. If you want to provide high dynamic range, high color
% depths images, please specify them as Matlab double matrices to
% Screen('MakeTexture') and set the optional flag 'floatprecision' to 1 or
% 2, i.e., hdrtex = Screen('MakeTexture', win, myHDRImage, [], [], 2);
%
% Psychtoolbox will represent such images with an internal precision of 10
% bits + 1 bit sign if you choose the 'floatprecision' flag to be 1. If you
% choose a 'floatprecision' flag of 2, PTB will represent the images with
% an internal precision of 23 bits + 1 bit sign. You can provide negative
% color values as well, e.g., -0.5. If you wonder what the use of this
% might be, have a careful look at the tutorial script...
% 'AdditiveBlendingForLinearSuperpositionTutorial.m'
% ... for an example of extremely fast drawing of luminance gratings with
% controllable size, orientation and contrast and correct linear superposition:
% 
% By default, PTB will use a 32-bit floating point framebuffer for your
% drawings, ie. the precision is way higher than needed for any high
% dynamic range/resolution display device in existence. The downside of this
% super-precision is that alpha-blending is not supported in this mode, unless
% you employ an NVidia Geforce 8000 series (and later) graphics card, or a
% ATI Radeon HD2000/3000 series graphics card (and later). If you need
% alpha-blending on older/other hardware then specify the optional flag
% 'kPsychNeed16BPCFloat' for the 'imagingmode' argument. This will reduce
% effective accuracy of the framebuffer to 10 bit precision, but allow for
% fast alpha-blending. 10 Bit precision are 4 bits less than the 14 bits
% that Bits++ can provide, but it will be possible to use the extra 14-10 =
% 4 bits for gamma correction of the display by employing a gamma
% correction shader.
%
% Gamma- and color correction:
%
% In Mono++ and Color++ mode, the hardware gamma tables of your graphics
% card and the Bits+ box can't be used for gamma- or color correction.
% However, PTB provides a much more powerful and flexible color correction
% system for this purpose. See "help PsychColorCorrection" for further
% explanation and usage examples for standard gamma correction.
%
% Graphics hardware requirements: Mono++ and Color++ mode require use of the
% Psychtoolbox imaging pipeline and floating point framebuffers. The
% minimum requirements are ATI Radeon X1000 series or NVidia Geforce-6800
% series and later graphics hardware. We currently recommend NVidia
% Geforce-8000 series or ATI Radeon HD-2000/3000 hardware for best results.
% However, this functions have been successfully tested on ATI Radeon X1600
% and NVidia Geforce-7800 hardware as well.
%
% All Bits++ modes supported by this function should work Plug & Play,
% requiring no changes to your stimulus code other than mentioned here to
% take full advantage of all functionality of Psychtoolbox just as with standard
% 8 bpc displays at the higher 14 bpc quality of Bits++. If you find this
% not to be the case then it's either an omission in our documentation
% or a bug - Please report it.

% History:
% 22.04.2007 Written (MK).
% xx.12.2007 Support for DIO T-Lock code generation (MK).
% 17.04.2008 Add support for overlay windows in Mono++ mode, and for color
%            correction/gamma correction via PsychColorCorrection (MK).
%  4.07.2009 Add support for other color correction methods like CLUT (MK).
% 14.12.2009 Add support for other target devices, e.g., DataPixx (MK).
%  3.01.2010 Some bugfixes to DataPixx support. (MK)
% 12.01.2013 Make compatible with PTB panelfitter. (MK)

global GL;

% Flag for validation: If not set to one, then this routine will check if
% proper operation of Bitsplusplus with GPU imaging has been verified.
persistent validated;

% Type of box: 0 = Bits+, 1 = Datapixx:
persistent targetdevicetype;

% Name strings:
persistent devname;
persistent drivername;
persistent bplusname;
persistent mononame;
persistent colorname;
persistent devbits;
persistent checkGPUEncoders;

% Vector that assigns overlay window handles to onscreen window handles:
persistent OverlayWindows;

% Encoded T-Lock display list handle for driving Bits++ DIO:
persistent tlockhandle;
% Counter of pending T-Lock display list blits: Zero == Disabled.
persistent blitTLockCode;
% Corrective x-offset for DIO blitting:
persistent tlockXOffset;

% Opmode for color conversion/buffer sampling in Color++ / C48 mode:
persistent colorConversionMode;

if nargin < 1
    error('You must specify a command in argument "cmd"!');
end

win = [];
winRect = [];

if cmd == 1
    % Fast callback path for PTB imaging pipeline. We got called from the
    % finalizer blit chain of the imaging pipeline, asking us to perform
    % some post-processing on the final framebuffer image, immediately
    % before bufferswap.
    %
    % Currently, the only supported operation is drawing of a DIO T-Lock
    % code into the framebuffer, for control of the DIO pins of the Bits++
    % box. The T-Lock code has been generated already by a call to
    % 'DIOCommand'. We just have to blit that "Code Image" to the
    % framebuffer. We can't use Screen() commands here as we are called
    % from inside Screen -- Screen is not reentrant!
    %
    % We only blit if there is something to blit. Then we reset to nothing
    % to blit:
    if blitTLockCode ~= 0
        glCallList(tlockhandle);
        blitTLockCode = blitTLockCode - 1;
    end
    
    return;
end

% Default debuglevel for output during initialization:
debuglevel = 1;

if isempty(validated)
    validated = 0;
    tlockhandle = 0;
    blitTLockCode = 0;
    tlockXOffset = 0;
    OverlayWindows = [];
    targetdevicetype = 0;
    drivername = 'BitsPlusPlus';
    devname = 'Bits+';
    bplusname = 'Bits++';
    mononame = 'Mono++';
    colorname = 'Color++';
    devbits = 14;
    checkGPUEncoders = 0;
    colorConversionMode = [];
end

if strcmpi(cmd, 'DIOCommand')

    % Setup new DIO command to be converted to T-Lock code and blitted:
    if nargin < 2 || isempty(arg)
        error('window handle for Bits++ onscreen window missing!');
    end
    
    if nargin < 3 || isempty(dummy)
        error('Number of repetitions for DIO command missing!');
    end

    if nargin < 6
        error('DIOCommand must have the parameters "Mask", "Command" and "Data"!');
    end

    mask = varargin{1};
    data = varargin{2};
    command = varargin{3};

    % Create or recreate our display list:
    glNewList(tlockhandle, GL.COMPILE);
    
    for i=1:size(mask, 1)
        % Process i'th row of command sequence:

        % Generate DIO T-Lock image as Matlab matrix:
        tlockdata = BitsPlusDIO2Matrix(mask(i), data(i,:), command(i));

        % Convert from Matlab matrix to OpenGL pixel format:
        encodedDIOdata = uint8(zeros(3, 508));
        % Pack 3 separate RGB planes into rows 1,2,3. As Matlabs data format is
        % column major order, this will end up as tightly packed pixel array in
        % format RGBRGBRGB.... just as glDrawPixels likes it.
        encodedDIOdata(1,:) = tlockdata(1,:,1);
        encodedDIOdata(2,:) = tlockdata(1,:,2);
        encodedDIOdata(3,:) = tlockdata(1,:,3);

        if nargin >= 7
            % Optional x, y blit position provided:
            xDIO = varargin{4};
            yDIO = varargin{5};
            xDIO = xDIO(i);
            yDIO = yDIO(i);
            
            if yDIO < 1
                yDIO = 1;
            end
        else
            % Set default position: 3rd scanline of display, so we don't get
            % into the way of a possible CLUT T-Lock code:
            xDIO = 0;
            yDIO = 3;
        end
        
        % Add command sequence for this T-Lock code to display list:
        glRasterPos2i(xDIO + tlockXOffset, yDIO);
        glDrawPixels(508, 1, GL.RGB, GL.UNSIGNED_BYTE, encodedDIOdata);
    end
    
    % Finish display list;
    glEndList;
        
    % Assign number of repetitions:
    blitTLockCode = dummy;

    % Done. Return.
    return;

end

if strcmpi(cmd, 'DIOCommandReset')
    % Dummy error check: arg will be used in later revisions...
    if nargin < 2 || isempty(arg)
        error('window handle for Bits++ onscreen window missing!');
    end
    
    % Disable T-Lock blitting:
    blitTLockCode = 0;
    return;
end

if strcmpi(cmd, 'SetTargetDeviceType')
    if nargin < 2
        error('targetdevicetype parameter missing!');
    end
    
    % Assign targetdevicetype to internal persistent variable:
    % A zero means: It is a regular CRS Bits+ box.
    % A 1 means: It is a VPixx DataPixx box which is sharing setup code
    % with Bits+ in this file:
    targetdevicetype = arg;
    
    switch (targetdevicetype)
        case 0,
            drivername = 'BitsPlusPlus';
            devname = 'Bits+';
            bplusname = 'Bits++';
            mononame = 'Mono++';
            colorname = 'Color++';
            devbits = 14;
            
        case 1,
            drivername = 'PsychDatapixx';
            devname = 'DataPixx';
            bplusname = 'L48';
            mononame = 'M16';
            colorname = 'C48';
            devbits = 16;
            
        otherwise
            error('Unknown targetdevicetype assigned in call to "SetTargetDeviceType"!');
    end
    
    return;
end


if strcmpi(cmd, 'SetColorConversionMode')
    % Set the mode of operation for color conversion in Color++ / C48 mode.
    % This is a mandatory call in that mode. As the effective output
    % resolution is only half the framebuffer resolution we need to decide
    % what tradeoff between aspect-ratio preservation, sampling precision etc.
    % to take.
    colorConversionMode = arg;
    return;
end

if strcmpi(cmd, 'TestGPUEncoders')
    % Perform check of GPU identity gamma tables and encoders during next
    % 'OpenWindowXXX' call in Datapixx mode. This is a one-shot, auto-reset
    % flag:
    checkGPUEncoders = 1;
    return;
end

if strcmpi(cmd, 'ForceUnvalidatedRun')
    % Enforce use of this routine without verification of correct function
    % of the imaging pipeline. This is used by the correctness test itself
    % in order to be able to run the validation.
    validated = 1;
    return;
end

if strcmpi(cmd, 'StoreValidation')
    % Enforce use of this routine without verification of correct function
    % of the imaging pipeline. This is used by the correctness test itself
    % in order to be able to run the validation.
    ValidateBitsPlusImaging(arg, 1, devname);
    return;
end

if strcmpi(cmd, 'LoadIdentityClut')
    % Load an identity CLUT into Bits++ at next Screen('Flip'). This is
    % just a little convenience wrapper around 'LoadNormalizedGammaTable':
    % Restore Bits++ Identity CLUT so it can be used as normal display:
    if nargin < 2 || isempty(arg)
        error('window handle for %s onscreen window missing!', devname);
    end
    linear_lut =  repmat(linspace(0, 1, 256)', 1, 3);
    Screen('LoadNormalizedGammaTable', arg, linear_lut, 2);
    return;
end

if strcmpi(cmd, 'OpenWindowBits++')
    % Execute the Screen('OpenWindow') command with proper flags, followed
    % by our own Initialization. Return values of 'OpenWindow'.
    %
    % This will set up the Bits++ mode of Bits++
        
    % Assign screen index:
    if nargin < 2 || isempty(arg) || ~isa(arg, 'double')
        error('%s: "OpenWindow..." called without valid screen handle.', drivername);
    end
    screenid = arg;

    % Assign optional clear color:
    if nargin < 3
        clearcolor = [];
    else
        clearcolor = dummy;
    end

    % windowRect is always full screen -- Anything else would make the
    % Bits++ display fail.
    winRect = [];

    % pixelSize is also fixed to 32 bit RGBA8 framebuffer:
    pixelSize = 32;

    % Same for double-buffering:
    numbuffers = 2;

    % stereomode we take...
    if nargin >= 7
        stereomode = varargin{4};
    else
        stereomode = [];
    end

    % multiSample gets forced to zero, as it would interfere
    % with Bits++ display controller:
    multiSample = 0;

    % Open the window, pass all parameters (partially modified or overriden), return Screen's return values:
    if nargin >= 9
        [win, winRect] = Screen('OpenWindow', screenid, clearcolor, winRect, pixelSize, numbuffers, stereomode, multiSample, varargin{6:end});
    else
        [win, winRect] = Screen('OpenWindow', screenid, clearcolor, winRect, pixelSize, numbuffers, stereomode, multiSample);
    end

    % Ok, if we reach this point then we've got a proper onscreen
    % window on the Bits++. Let's reassign our arguments and continue with
    % the init sequence:

    % First load the graphics hardwares gamma table with an identity mapping,
    % so it doesn't interfere with Bits++ -- Functions from Bits++ toolbox.
    LoadIdentityClut(win);

    % We need the GL for DIO T-Lock setup:
    if isempty(GL)
        % Load & Initalize constants and moglcore, but don't set the 3D gfx
        % flag for Screen():
        InitializeMatlabOpenGL([], [], 1);
    end;

    % Test accuracy/correctness of GPU's rasterizer for different output
    % positioning methods: Return (non-zero) dx,dy offsets, if any:
    [rpfx, rpfy, rpix, rpiy, vix] = RasterizerOffsets(win, drivername); %#ok<ASGLU>
        
    if rpix~=0
        tlockXOffset = -rpix;
        fprintf('OpenWindow%s: Applying corrective horizontal DIO T-Lock offset of %i pixels for buggy graphics card driver. Will hopefully fix it...\n', bplusname, tlockXOffset);        
    end

    if targetdevicetype == 1 && checkGPUEncoders
        % Perform DataPixx builtin diagnostics to detect problems with
        % wrong GPU gamma tables or GPU dithering:
        checkGPUEncoders = 0;
        if PsychDataPixx('CheckGPUSanity', win, tlockXOffset)
            % Ohoh, trouble ahead! The driver detected problems with the
            % GPU and wasn't able to auto-correct them.
            fprintf('%s: CAUTION! DataPixx internal diagnostic detected problems with your graphics card driver which it could not correct by itself!\n', drivername);
        end
    end
    
    % Now enable finalizer hook chains and load them with the special Bits++
    % command for T-Lock based Bits++ internal CLUT updates:
    if vix~=0
        % vix is wrong offset, therefore negate it to get corrective offset:
        vix = -vix;
        fprintf('OpenWindow%s: Applying corrective horizontal offset of %i pixels for buggy graphics card driver. Will hopefully fix it...\n', bplusname, vix);
        offsetstring = sprintf('xPosition=%i', vix);
    else
        offsetstring = '';
    end
    
    if targetdevicetype == 0
        Screen('HookFunction', win, 'PrependBuiltin', 'LeftFinalizerBlitChain', 'Builtin:RenderClutBits++', offsetstring);
    end
    
    if targetdevicetype == 1
        % We need this weird evalin('base', ...); wrapper so the
        % function gets called from the base-workspace, where the
        % IMAGINGPIPE_GAMMATABLE variable is defined. We can only
        % define it there reliably due to incompatibilities between
        % Matlab and Octave in variable assignment inside Screen() :-(
        rclutcmd = 'evalin(''base'', ''PsychDataPixx(1, IMAGINGPIPE_GAMMATABLE);'');';
        Screen('HookFunction', win, 'PrependMFunction', 'LeftFinalizerBlitChain', 'Upload new clut into DataPixx callback', rclutcmd);
    end
    
    Screen('HookFunction', win, 'Enable', 'LeftFinalizerBlitChain');

    if (~isempty(stereomode) && stereomode == 1)
        % This is only needed on quad-buffered stereo contexts for Bits+.
        % Enable CLUT updates via T-Lock on right stereo buffer as well:

        if targetdevicetype == 0
            Screen('HookFunction', win, 'PrependBuiltin', 'RightFinalizerBlitChain', 'Builtin:RenderClutBits++', offsetstring);
        end
        
        if targetdevicetype == 1
            Screen('HookFunction', win, 'PrependMFunction', 'RightFinalizerBlitChain', 'Upload new clut into DataPixx callback', rclutcmd);
        end
        
        Screen('HookFunction', win, 'Enable', 'RightFinalizerBlitChain');
    end

    if targetdevicetype == 0
        % Setup finalizer callback for DIO T-Lock updates:
        tlockhandle = SetupDIOFinalizer(win, stereomode);
    end
    
    % Load an identity CLUT into the Bits++ to start with:
    linear_lut =  repmat(linspace(0, 1, 256)', 1, 3);
    Screen('LoadNormalizedGammaTable', win, linear_lut, 2);
    
    % Check validation:
    if ~validated
        % MK: Actually, don't! Validation code doesn't check/validate
        % anything in Bits++ mode, so this is pointless... Leave it here
        % for documentation.
        % ValidateBitsPlusImaging(win, 0, devname);
    end
    
    % Reset validation flag after first run:
    validated = 0;
    
    % Ready!
    return;
end

if strcmpi(cmd, 'OpenWindowMono++') || strcmpi(cmd, 'OpenWindowMono++WithOverlay') || strcmpi(cmd, 'OpenWindowColor++')
    % Execute the Screen('OpenWindow') command with proper flags, followed
    % by our own Initialization. Return values of 'OpenWindow'.
    %
    % This will set up the Mono++ or Color++ mode of Bits++
    
    % Assign screen index:
    if nargin < 2 || isempty(arg) || ~isa(arg, 'double')
        error('%s: "OpenWindow..." called without valid screen handle.', drivername);
    end
    screenid = arg;

    % Assign optional clear color:
    if nargin < 3
        clearcolor = [];
    else
        clearcolor = dummy;
    end

    if isempty(clearcolor)
        clearcolor = 1.0;
    end
    
    % windowRect is always full screen -- Anything else would make the
    % Bits++ display fail.
    winRect = [];

    % pixelSize is also fixed to 32 bit RGBA8 framebuffer:
    pixelSize = 32;

    % Same for double-buffering:
    numbuffers = 2;

    % stereomode we take...
    if nargin >= 7
        stereomode = varargin{4};
    else
        stereomode = [];
    end

    % Retrieve multiSample setting:
    if nargin >= 8
        multiSample = varargin{5};
    else
        multiSample = [];
    end

    % Imaging mode we take - and combine it with our own requirements:
    if nargin >= 9
        imagingmode = varargin{6};
    else
        imagingmode = 0;
    end

    % For imagingmode we need at least fast backingstore, the output
    % formatter enabled and some high precision color buffer. We default to
    % 32 bpc floating point, the only safe choice accross different graphics cards
    % from different vendors, but the users imagingmode setting is free to
    % override this with a 16 bpc fixed buffer. 16 bpc float works as well
    % but can't use the full Bits++ color range at full precision.
    if bitand(imagingmode, kPsychNeed16BPCFloat) || bitand(imagingmode, kPsychNeed16BPCFixed) || bitand(imagingmode, kPsychUse32BPCFloatAsap)
        % User specified override: Use it.
        ourspec = 0;
    else
        % No user specified accuracy. We play safe and choose the highest
        % one:
        ourspec = kPsychNeed32BPCFloat;
    end

    % Imagingmode must at least include the following:
    imagingmode = mor(imagingmode, kPsychNeedFastBackingStore, kPsychNeedOutputConversion, ourspec);

    if strcmpi(cmd, 'OpenWindowColor++')
        if isempty(colorConversionMode)
            sca;
            fprintf('The new mandatory parameter "colorConversionMode" is missing!\n');
            fprintf('If you used BitsPlusPlus(''OpenWindowColor++'', ...); to get here, then\n');
            fprintf('add the command BitsPlusPlus(''SetColorConversionMode'', mode);\n');
            fprintf('immediately before the BitsPlusPlus(''OpenWindowColor++'', ...); command.\n\n');
            fprintf('If you used the more modern and recommended PsychImaging() commands to get here, then\n');
            fprintf('change your call to PsychImaging(''AddTask'', ''General'', ''EnableBits++Color++Output'');\n');
            fprintf('or to PsychImaging(''AddTask'', ''General'', ''EnableDataPixxC48Output''); into a call to \n');
            fprintf('PsychImaging(''AddTask'', ''General'', ''EnableBits++Color++Output'', mode);\n');
            fprintf('or PsychImaging(''AddTask'', ''General'', ''EnableDataPixxC48Output'', mode);\n\n');
            fprintf('The new parameter "mode" must be 0 if you want exactly the old behaviour back.\n');
            fprintf('For new code, you will likely want to use a value of 1 or 2 to preserve correct\n');
            fprintf('aspect ratio.\n\n');
            fprintf('Please read the help section for the PsychImaging() command ("help PsychImaging")\n');
            fprintf('for the ''EnableBits++Color++Output'' subcommand. It explains the meaning of the different\n');
            fprintf('possible settings of "mode".\n\n');
            
            error('Mandatory parameter "colorConversionMode" is missing!');
        end
        
        if ~ismember(colorConversionMode, [0,1,2]);
            sca;
            fprintf('The provided "colorConversionMode" parameter %i is not one of the valid values 0, 1 or 2!\n', colorConversionMode);
            error('Mandatory parameter "colorConversionMode" is invalid!');
        end
        
        if colorConversionMode == 0
            % In Color++ mode with "classic" conversion, we only have half the
            % effective horizontal resolution. Tell PTB to take this into
            % account for all relevant calculations:
            imagingmode = mor(imagingmode, kPsychNeedHalfWidthWindow);
        end        
    end

    % Open the window, pass all parameters (partially modified or overriden), return Screen's return values:
    % Note that we clear to black (==0), because we set the real background
    % clear color "further down the road" after we've established our
    % default color range of 0.0 - 1.0, ie. in the normalized 0 - 1 range.
    if nargin > 9
        [win, winRect] = Screen('OpenWindow', screenid, 0, winRect, pixelSize, numbuffers, stereomode, multiSample, imagingmode, varargin{7:end});
    else
        [win, winRect] = Screen('OpenWindow', screenid, 0, winRect, pixelSize, numbuffers, stereomode, multiSample, imagingmode);
    end

    % Ok, if we reach this point then we've got a proper onscreen
    % window on the Bits++. Let's reassign our arguments and continue with
    % the init sequence:

    % Some more diagnostics and info for user:
    winfo = Screen('GetWindowInfo', win);
    
    % Unconditional support for 32 bpc float drawable requested?
    havespoken = 0;
    if ~bitand(imagingmode, kPsychNeed32BPCFloat)
        % Nope. Conditional support requested?
        if (bitand(imagingmode, kPsychUse32BPCFloatAsap) && winfo.GLSupportsBlendingUpToBpc < 32)
            % Conditional use of 32 bpc float buffers requested, but GPU
            % doesn't support 32 bpc float blending --> drawBuffer will only be
            % 16 bpc -- Loss of precision!
            fprintf('PTB - Info: Your framebuffer is only configured to provide about 10-11 bits of precision, because your\n');
            fprintf('PTB - Info: script requested support for simultaneous alpha-blending and high precision, but your hardware is not\n');
            fprintf('PTB - Info: capable of supporting highest precision with alpha-blending enabled. You will therefore only\n');
            fprintf('PTB - Info: be able to use about 11 bits out of the %i bits precision that %s provides for stimulus definition.\n', devbits, devname);
            fprintf('PTB - Info: Stimulus postprocessing, e.g., gamma correction, will still make good use of all %i bits though.\n', devbits);
            fprintf('PTB - Info: You can either live with this limitation, or do not use alpha-blending or upgrade your graphics\n');
            fprintf('PTB - Info: hardware to Direct3D-10 compliant hardware, e.g., ATI Radeon HD-3000 or NVidia Geforce-8000 and later.\n\n');
            havespoken = 1;
        end

        if bitand(imagingmode, kPsychNeed16BPCFloat)
            fprintf('PTB - Info: Your framebuffer is only configured to provide about 10-11 bits of precision, because your\n');
            fprintf('PTB - Info: script requested only 16 bpc float precision. You will therefore only be able to use\n');
            fprintf('PTB - Info: about 11 bits out of the %i bits precision that %s provides for stimulus drawing.\n', devbits, devname);
            fprintf('PTB - Info: If you want to use the full %i bit precision, you will need to request a 32 bpc float framebuffer.\n\n', devbits);
            havespoken = 1;
        end

        if bitand(imagingmode, kPsychNeed16BPCFixed)
            fprintf('PTB - Info: Your framebuffer is configured to provide 16 bits of precision, because your\n');
            fprintf('PTB - Info: script requested 16 bits fixed precision. %s will be able to finally output %i bits precision.\n', devname, devbits);
            fprintf('PTB - Info: Alpha-blending will not work at this configuration with your hardware though. Choose a different\n');            
            fprintf('PTB - Info: mode if you need alpha-blending and high precision.\n\n');
            havespoken = 1;
        end
    end

    if (havespoken == 0) && (bitand(imagingmode, kPsychNeed32BPCFloat) || bitand(imagingmode, kPsychUse32BPCFloatAsap))
        fprintf('PTB - Info: Your framebuffer is configured for maximum precision. All internal processing will be done\n');
        fprintf('PTB - Info: with about 23 bits of precision -- %s will be able to finally output with %i bits precision.\n', devname, devbits);
        if winfo.GLSupportsBlendingUpToBpc < 32
            fprintf('PTB - Info: Alpha-blending will not work at this precision with your hardware though.\n');
            fprintf('PTB - Info: You can either live with this limitation, or upgrade your graphics hardware to Direct3D-10\n');
            fprintf('PTB - Info: compliant hardware, e.g., ATI Radeon HD-3000 or NVidia Geforce-8000 and later.\n\n');
        else
            fprintf('PTB - Info: Alpha-blending should be fully supported at this precision by your hardware.\n\n');            
        end
    end
    
    if strcmpi(cmd, 'OpenWindowColor++')
        if colorConversionMode == 0
            fprintf('PTB - Info: Classic half horizontal resolution color conversion for %s mode selected.\n', colorname);
            fprintf('PTB - Info: Aspect ratio will be horizontally distorted, ie., 2:1.\n');
        end

        if colorConversionMode == 1
            fprintf('PTB - Info: Aspect ratio preserving half horizontal resolution color conversion for %s\n', colorname);
            fprintf('PTB - Info: mode selected. All odd-numbered pixel columns will be ignored/skipped.\n');
        end

        if colorConversionMode == 2
            fprintf('PTB - Info: Aspect ratio preserving bilinear color conversion for %s mode selected.\n', colorname);
            fprintf('PTB - Info: Will average color between adjacent even/odd pixel columns.\n');
        end
        
        fprintf('\n');
    end
    
    % First load the graphics hardwares gamma table with an identity mapping,
    % so it doesn't interfere with Bits++ -- Function from Bits++ toolbox.
    LoadIdentityClut(win);

    % Backup current gfx-settings, so we can restore them after
    % modifications: The LoadGLSLProgramFromFiles() routine enables this
    % implicitely. This is unwanted in case we are in pure 2D mode, so we
    % need to undo it below...
    ogl = Screen('Preference', 'Enable3DGraphics');

    % Create and retrieve a compiled shader and idString-Snippet for
    % use with the formatting shader to allow for final
    % color-transformations immediately before Mono++ conversion. This
    % is mostly meant to implement gammacorrection, clamping or other
    % transformations needed for a well calibrated display:
    [icmShaders, icmIdString, icmConfig] = PsychColorCorrection('GetCompiledShaders', win, debuglevel);
    
    % Operate in Mono++ mode or Color++ mode?
    if strcmpi(cmd, 'OpenWindowMono++') || strcmpi(cmd, 'OpenWindowMono++WithOverlay')
        % Setup for Mono++ mode:
        
        if strcmpi(cmd, 'OpenWindowMono++WithOverlay')
            useOverlay = 1;
        else
            useOverlay = 0;
        end
        
        % Use of overlay plane requested?
        if useOverlay
            % Create additional shader for overlay texel fetch:
            % Our gpu panel scaler might be active, so the size of the
            % virtual window - and thereby our overlay window - can be
            % different from the output framebuffer size. As the sampling
            % 'pos'ition for the overlay is always provided in framebuffer
            % coordinates, we need to subsample in the overlay fetch.
            % Calculate proper scaling factor, based on virtual and real
            % framebuffer size:
            [wC, hC] = Screen('WindowSize', win);
            [wF, hF] = Screen('WindowSize', win, 1);
            sampleX = wC / wF;
            sampleY = hC / hF;
            
            % Build the shader:
            shSrc = sprintf('uniform sampler2DRect overlayImage; float getMonoOverlayIndex(vec2 pos) { return(texture2DRect(overlayImage, pos * vec2(%f, %f)).r); }', sampleX, sampleY);

            % Create Offscreen window for the overlay. It has the same size as
            % the onscreen window, but only 8 bpc fixed depth and a completely black
            % background -- fully transparent by default.
            overlaywin = Screen('OpenOffscreenWindow', win, 0, [], 8);

            % Retrieve low-level OpenGl texture handle to the window:
            overlaytex = Screen('GetOpenGLTexture', win, overlaywin);
            
        else
            % No.: Create "no-op" shader for zero overlay:
            shSrc = 'float getMonoOverlayIndex(vec2 pos) { return(0.0); }';
        end

        % Build shader from source:
        overlayShader = glCreateShader(GL.FRAGMENT_SHADER);
        glShaderSource(overlayShader, shSrc);
        glCompileShader(overlayShader);

        % Attach to list of shaders:
        icmShaders(end+1) = overlayShader;

        % Load Bits++ Mono++ formatting shader:
        shader = LoadGLSLProgramFromFiles('Bits++_Mono++_FormattingShader', debuglevel, icmShaders);

        if useOverlay
            % Ok, overlay requested. Setup shader's overlayImage sampler to
            % texture unit 1 and setup proper pString, so unit 1 has
            % overlay bound during blit operation:
            pString = sprintf('TEXTURERECT2D(1)=%i', overlaytex);
            
            glUseProgram(shader);
            glUniform1i(glGetUniformLocation(shader, 'overlayImage'), 1);
            glUseProgram(0);
            
            % Store window handle of overlay window for this onscreen
            % window for later retrieval:
            OverlayWindows(win) = overlaywin;
        else
            pString = '';
        end

        % Now enable output formatter hook chain and load them with the special Bits++
        % Mono++ data formatting shader: We append the shader because it
        % absolutely must be the last shader to execute in that chain!
        idString = sprintf('Mono++ output formatting shader for CRS Bits++ : %s', icmIdString);
        pString  = [ pString ' ' icmConfig ];
        Screen('HookFunction', win, 'AppendShader', 'FinalOutputFormattingBlit', idString, shader, pString);        
    else
        % Setup for Color++ mode:

        % No support for overlays in Color++ mode:
        useOverlay = 0;

        if colorConversionMode == 2
            % Load "bilinear" Bits++ Color++ formatting shader for bilinear
            % sampling/averaging between adjacent even/odd pixel columns:
            shader = LoadGLSLProgramFromFiles('Bits++_Color++_BilinearFormattingShader', debuglevel, icmShaders);
        else
            % Load "classic" Bits++ Color++ formatting shader for non-interpolated
            % sampling:
            shader = LoadGLSLProgramFromFiles('Bits++_Color++_FormattingShader', debuglevel, icmShaders);
        end
                
        if colorConversionMode == 2
            % "Bilinear" mode: Aspect ratio correct, full-width source
            % framebuffer. Adjacent even/odd pixels are combined to a
            % single output pixel via averaging, ie., the output color is
            % the mean value of adjacent even/odd pixels:
            
            % Empty pString, no scaling needed:
            pString  = '';
        else
            if colorConversionMode == 0
                % "Classic" mode: Aspect ratio distorted half-width source framebuffer:
                sampleSpacing = 0.5;
                pString  = 'Scaling:2.0:1.0';
            end

            if colorConversionMode == 1
                % "Subsample" mode: Aspect ratio correct, full-width source
                % framebuffer, but sampled only at even pixel location, ie.
                % each second pixel column is skipped:
                sampleSpacing = 1.0;

                % Empty pString, no scaling needed:
                pString  = '';
            end

            glUseProgram(shader);
            glUniform1f(glGetUniformLocation(shader, 'sampleSpacing'), sampleSpacing);
            glUseProgram(0);
        end
        
        % Now enable output formatter hook chain and load them with the special Bits++
        % Color++ data formatting shader: We append the shader because it
        % absolutely must be the last shader to execute in that chain!
        % We apply a scaling of 2.0 in horizontal direction for the output
        % blit, to take the fact into account that the internal window
        % buffers only have half display width.
        idString = sprintf('Color++ output formatting shader for CRS Bits++ : %s', icmIdString);
        pString  = [ pString ' ' icmConfig ];
        Screen('HookFunction', win, 'AppendShader', 'FinalOutputFormattingBlit', idString, shader, pString);        
    end

    % Setup shaders image source as the first texture unit, this is by
    % definition of how the imaging pipe works. Don't think really needed,
    % as this is the default, but its good practice to not rely on such
    % things...
    glUseProgram(shader);
    glUniform1i(glGetUniformLocation(shader, 'Image'), 0);
    glUseProgram(0);

    % Perform any setup steps that may be needed by the color correction
    % routines. Must be called after 'shader' creation and attachment to
    % the imaging pipe:
    PsychColorCorrection('ApplyPostGLSLLinkSetup', win, 'FinalFormatting');
    
    % Test accuracy/correctness of GPU's rasterizer for different output
    % positioning methods: Return (non-zero) dx,dy offsets, if any:
    [rpfx, rpfy, rpix, rpiy, vix] = RasterizerOffsets(win, drivername); %#ok<ASGLU>
        
    if rpix~=0
        tlockXOffset = -rpix;
        fprintf('%s: Applying corrective horizontal DIO T-Lock offset of %i pixels for buggy graphics card driver. Will hopefully fix it...\n', drivername, tlockXOffset);        
    end

    if targetdevicetype == 1 && checkGPUEncoders
        % Perform DataPixx builtin diagnostics to detect problems with
        % wrong GPU gamma tables or GPU dithering:
        checkGPUEncoders = 0;
        if PsychDataPixx('CheckGPUSanity', win, tlockXOffset)
            % Ohoh, trouble ahead! The driver detected problems with the
            % GPU and wasn't able to auto-correct them.
            fprintf('%s: CAUTION! DataPixx internal diagnostic detected problems with your graphics card driver which it could not correct by itself!\n', drivername);
        end
    end
    
    % Enable framebuffer output formatter: From this point on, all visual
    % output will be reformatted to Bits++ framebuffer format at each
    % invokation of Screen('DrawingFinished') or Screen('Flip'), whatever
    % comes first.
    Screen('HookFunction', win, 'Enable', 'FinalOutputFormattingBlit');

    % When using the overlay, we need to allow for CLUT updates as well, so
    % usercode can define and change overlay colors:
    if useOverlay
        % Now enable finalizer hook chains and load them with the special Bits++
        % command for T-Lock based Bits++ internal CLUT updates:
        if vix~=0
            % vix is wrong offset, therefore negate it to get corrective offset:
            vix = -vix;
            fprintf('OpenWindow%sWithOverlay: Applying corrective horizontal offset of %i pixels for buggy graphics card driver. Will hopefully fix it...\n', mononame, vix);
            offsetstring = sprintf('xPosition=%i', vix);
        else
            offsetstring = '';
        end

        if targetdevicetype == 0
            Screen('HookFunction', win, 'PrependBuiltin', 'LeftFinalizerBlitChain', 'Builtin:RenderClutBits++', offsetstring);
        end

        if targetdevicetype == 1
            % We need this weird evalin('base', ...); wrapper so the
            % function gets called from the base-workspace, where the
            % IMAGINGPIPE_GAMMATABLE variable is defined. We can only
            % define it there reliably due to incompatibilities between
            % Matlab and Octave in variable assignment inside Screen() :-(
            rclutcmd = 'evalin(''base'', ''PsychDataPixx(1, IMAGINGPIPE_GAMMATABLE);'');';
            Screen('HookFunction', win, 'PrependMFunction', 'LeftFinalizerBlitChain', 'Upload new clut into DataPixx callback', rclutcmd);
        end

        Screen('HookFunction', win, 'Enable', 'LeftFinalizerBlitChain');

        if (~isempty(stereomode) && stereomode == 1)
            % This is only needed on quad-buffered stereo contexts for Bits+.
            % Enable CLUT updates via T-Lock on right stereo buffer as well:

            if targetdevicetype == 0
                Screen('HookFunction', win, 'PrependBuiltin', 'RightFinalizerBlitChain', 'Builtin:RenderClutBits++', offsetstring);
            end

            if targetdevicetype == 1
                Screen('HookFunction', win, 'PrependMFunction', 'RightFinalizerBlitChain', 'Upload new clut into DataPixx callback', rclutcmd);
            end

            Screen('HookFunction', win, 'Enable', 'RightFinalizerBlitChain');
        end
        
        % Load an identity CLUT into the Bits++ to start with:
        linear_lut =  repmat(linspace(0, 1, 256)', 1, 3);
        Screen('LoadNormalizedGammaTable', win, linear_lut, 2);
    end
    
    if targetdevicetype == 0
        % Setup finalizer callback for DIO T-Lock updates:
        tlockhandle = SetupDIOFinalizer(win, stereomode);
    end
    
    % Restore old graphics preferences:
    Screen('Preference', 'Enable3DGraphics', ogl);

    % Set color range to 0.0 - 1.0: This makes more sense than the normal
    % 0-255 values. Try to disable color clamping. This may fail and
    % produce a PTB warning, but if it succeeds then we're better off for
    % the 2D drawing commands...
    Screen('ColorRange', win, 1, 0);

    % Set Screen background clear color, in normalized 0.0 - 1.0 range:
    if (max(clearcolor) > 1) && (all(round(clearcolor) == clearcolor))
        % Looks like someone's feeding old style 0-255 integer values as
        % clearcolor. Output a warning to tell about the expected 0.0 - 1.0
        % range of values:
        warning(sprintf('\n\n%s: You specified a ''clearcolor'' argument for the OpenWindow command that looks \nlike an old 0-255 value instead of the wanted value in the 0.0-1.0 range. Please update your code for correct behaviour.', drivername)); %#ok<WNTAG,SPWRN>
    end
    
    % Set the background clear color via old fullscreen 'FillRect' trick,
    % followed by a flip:
    Screen('FillRect', win, clearcolor);
    Screen('Flip', win);
    
    % Check validation:
    if ~validated
        ValidateBitsPlusImaging(win, 0, devname);
    end

    % Reset validation flag after first run:
    validated = 0;

    % Reset colorConversionMode after opening the window. It is a one-shot
    % parameter:
    colorConversionMode = [];
    
    % Ready!
    return;
end

if strcmpi(cmd, 'GetOverlayWindow')
    % Assign onscreen window index:
    if nargin < 2 || isempty(arg) || ~isa(arg, 'double')
        error('%s: "GetOverlayWindow" called without valid onscreen window handle.', drivername);
    end
    win = arg;
    
    if win < 1 || win > length(OverlayWindows)
        error('%s: "GetOverlayWindow": No overlay associated with given onscreen window.', drivername);
    end

    if OverlayWindows(win) == 0
        error('%s: "GetOverlayWindow": No overlay associated with given onscreen window.', drivername);
    end

    % Ok, this 'win'dow has an overlay: Return its offscreen 'win'dow handle:
    win = OverlayWindows(win);
    % And the defining rectangle of the overlay:
    winRect = Screen('Rect', win);
    
    return;
end

error('%s: Unknown subcommand provided. Read "help BitsPlusPlus".', drivername);
end

% Helper function: Check if system already validated for current settings:
function ValidateBitsPlusImaging(win, writefile, devname)
    
    % Compute fingerprint of this system configuration:
    validated = 0;
    global GL;
    
    screenid = Screen('WindowScreenNumber', win);
    [w, h] = Screen('WindowSize', screenid);
    d = Screen('PixelSize', win);
    v = Screen('Version');
    v = v.version;
    gfxconfig = [ glGetString(GL.VENDOR) ':' glGetString(GL.RENDERER) ':' glGetString(GL.VERSION) ];
    gfxconfig = sprintf('%s : Screen %i : Resolution %i x %i x %i : ScreenVersion = %s', gfxconfig, screenid, w, h, d, v);
    
    if ~writefile
        % Check if a validation file exists and if it contains this
        % configuration:
        fid = fopen([PsychtoolboxConfigDir 'ptbbitsplusplusvalidationfile.txt'], 'r');
        if fid~=-1
            while ~feof(fid)
                vconf = fgetl(fid);
                if strcmp(vconf, gfxconfig)
                    validated = 1;
                    break;
                end
            end
            fclose(fid);
        end

        if ~validated
            fprintf('\n\n------------------------------------------------------------------------------------------------------------------\n')
            fprintf('\n\nThis specific configuration of graphics hardware, graphics driver and Psychtoolbox version has not yet been tested\n');
            fprintf('for correct working with %s for the given display screen, screen resolution and color depths.\n\n', devname);
            fprintf('Please run the test script "BitsPlusImagingPipelineTest(%i);" once, so this configuration can be verified.\n', Screen('WindowScreenNumber', win));
            fprintf('After that test script suceeded, re-run your experiment script.\nThanks.\n');
            fprintf('\n');
            fprintf('Configuration to verify: %s\n', gfxconfig);

            RestoreCluts;
            Screen('CloseAll'); ShowCursor; Priority(0);
            
            error('Configuration not yet verified. Please do it now.');
        end
    end
    
    if writefile
        % Append current configuration to file to mark it as verified:
        [fid msg]= fopen([PsychtoolboxConfigDir 'ptbbitsplusplusvalidationfile.txt'], 'a');
        if fid == -1
            RestoreCluts;
            sca;
            error('Could not write validation file %s to filesystem [%s].', [PsychtoolboxConfigDir 'ptbbitsplusplusvalidationfile.txt'], msg);
        end

        % Append line:
        fprintf(fid, [gfxconfig '\n']);
        fclose(fid);
    end
end

% Helper function for setup of finalizer blit chains in all modes. Sets up
% callback into our file for T-Lock drawing etc...
function displist = SetupDIOFinalizer(win, stereomode)
    
    % Generate unique display list handle for later use:
    displist = glGenLists(1);
    
    % Now enable finalizer hook chains and load them with the special Bits++
    % command for T-Lock based Bits++ DIO updates:
    Screen('HookFunction', win, 'PrependMFunction', 'LeftFinalizerBlitChain', 'Render T-Lock DIO data callback', 'BitsPlusPlus(1);');
    Screen('HookFunction', win, 'Enable', 'LeftFinalizerBlitChain');

    if (~isempty(stereomode) && stereomode == 1)
        % This is only needed on quad-buffered stereo contexts.
        Screen('HookFunction', win, 'PrependMFunction', 'RightFinalizerBlitChain', 'Render T-Lock DIO data callback',  'BitsPlusPlus(1);');
        Screen('HookFunction', win, 'Enable', 'RightFinalizerBlitChain');
    end

end

function [rpfx, rpfy, rpix, rpiy, vix, viy] = RasterizerOffsets(win, drivername)

    global GL;

    winfo = Screen('GetWindowInfo', win);
    if bitand(winfo.ImagingMode, kPsychNeedFastBackingStore)
        % Imaging pipeline: Read from drawBuffer. Important in case imaging
        % pipeline applies geometric transformations, e.g., gpu panel
        % fitting. Otherwise we'd get false positives in test below.
        readbuffer = 'drawBuffer';
    else
        % Read from system backbuffer:
        readbuffer = 'backBuffer';
    end
    
    % Test for off-by-one bugs in graphics drivers / GPU's and compute
    % corrective offsets for our Bits++ T-Lock blitters...

    % glRasterPos2f(): Used by Screen('PutImage') for output-positioning:
    
    % Clear out top-left 20x20 rectangle of framebuffer:
    Screen('FillRect', win, 0, [0 0 20 20]);

    % Define drawposition via glRasterPos2f:
    glRasterPos2f(2, 1);

    % Draw RGB = [128, 0, 0] pixel to that location:
    testpixel = uint8([128 0 0]);
    glDrawPixels(1, 1, GL.RGB, GL.UNSIGNED_BYTE, testpixel);

    % Sync the pipeline, so we know the backbuffer contains the result:
    Screen('DrawingFinished', win, 0, 1);

    % Read top-left 4x4 rectangle back, only the red channel:
    testreadback = Screen('GetImage', win, [0 0 4 4], readbuffer, 0, 1);

    % Must flip here, to clear the "drawingfinished" state from above:
    Screen('Flip', win);
    
    % Find location of red == 128 pixel:
    pixposition = find(testreadback == 128);
    if ~isempty(pixposition)
        [pixy, pixx] = ind2sub(size(testreadback), pixposition);
        % Map from Matlab indexing to OpenGL indexing: Only x is remapped,
        % y-offset is consistent due to 1 offset inside our y-origin inside
        % Screen:
        pixx = pixx - 1;
    else
        pixy = -1;
        pixx = -1;
    end

    rpfx = pixx - 2;
    rpfy = pixy - 1;

    % At expected location?
    if rpfx~=0
        fprintf('%s:GPU-Rasterizertest: Warning: glRasterPos2f() command draws at wrong position (Offset %i, %i)!\n', drivername, rpfx, rpfy);
    end

    % glRasterPos2i(): Used by our DIO T-Lock blitter for output-positioning:
    
    % Clear out top-left 20x20 rectangle of framebuffer:
    Screen('FillRect', win, 0, [0 0 20 20]);

    % Define drawposition via glRasterPos2i:
    glRasterPos2i(2, 1);

    % Draw RGB = [128, 0, 0] pixel to that location:
    testpixel = uint8([128 0 0]);
    glDrawPixels(1, 1, GL.RGB, GL.UNSIGNED_BYTE, testpixel);

    % Sync the pipeline, so we know the backbuffer contains the result:
    Screen('DrawingFinished', win, 0, 1);

    % Read top-left 4x4 rectangle back, only the red channel:
    testreadback = Screen('GetImage', win, [0 0 4 4], readbuffer, 0, 1);

    % Must flip here, to clear the "drawingfinished" state from above:
    Screen('Flip', win);

    % Find location of red == 128 pixel:
    pixposition = find(testreadback == 128);
    if ~isempty(pixposition)
        [pixy, pixx] = ind2sub(size(testreadback), pixposition);
        % Map from Matlab indexing to OpenGL indexing: Only x is remapped,
        % y-offset is consistent due to 1 offset inside our y-origin inside
        % Screen:
        pixx = pixx - 1;
    else
        pixy = -1;
        pixx = -1;
    end

    rpix = pixx - 2;
    rpiy = pixy - 1;

    % At expected location?
    if rpix~=0
        fprintf('%s:GPU-Rasterizertest: Warning: glRasterPos2i() command draws at wrong position (Offset %i, %i)!\n', drivername, rpix, rpiy);
    end

    % glVertex2i(): Used by Screen's CLUT T-Lock blitter for output-positioning:
    
    % Clear out top-left 20x20 rectangle of framebuffer:
    Screen('FillRect', win, 0, [0 0 20 20]);

    glPointSize(1);
    glBegin(GL.POINTS);
    % Draw RGB = [128, 0, 0] pixel:
    glColor3ub(128, 0, 0);
    % Submit glVertex2i at test location:
    glVertex2i(2, 1);
    glEnd;
    
    % Sync the pipeline, so we know the backbuffer contains the result:
    Screen('DrawingFinished', win, 0, 1);

    % Read top-left 4x4 rectangle back, only the red channel:
    testreadback = Screen('GetImage', win, [0 0 4 4], readbuffer, 0, 1);

    % Must flip here, to clear the "drawingfinished" state from above:
    Screen('Flip', win);
    
    % Find location of red == 128 pixel:
    pixposition = find(testreadback == 128);
    if ~isempty(pixposition)
        [pixy, pixx] = ind2sub(size(testreadback), pixposition);
        % Map from Matlab indexing to OpenGL indexing: Only x is remapped,
        % y-offset is consistent due to 1 offset inside our y-origin inside
        % Screen:
        pixx = pixx - 1;
    else
        pixy = -1;
        pixx = -1;
    end

    vix = pixx - 2;
    viy = pixy - 1;

    % At expected location?
    if vix~=0
        fprintf('%s:GPU-Rasterizertest: Warning: glVertex2i() command draws at wrong position (Offset %i, %i)!\n', drivername, vix, viy);
    end
end
