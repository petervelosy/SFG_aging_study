function offscreenWindow = createTextFeedbackOffscreenWindow(text, win, backGroundColor, rect)
    offscreenWindow = Screen('OpenOffscreenWindow', win, backGroundColor, rect);
    Screen('BlendFunction', offscreenWindow, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('TextSize', offscreenWindow, 26);
    Screen('DrawText', offscreenWindow, text, xCenter-50, yCenter-15, textColor);
end