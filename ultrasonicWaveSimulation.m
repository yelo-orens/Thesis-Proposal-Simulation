%% N=2 Real-World Phased Array (360° View - Steered to 0°)
clear; clc; close all;

% === PARAMETERS ===
N = 2;                  
f = 40000;              % 40 kHz
c = 343;                
d = 10 / 1000;          % 10mm spacing
theta0 = 45;             % Target Steering Angle

% === CALCULATIONS ===
lambda = c/f;
k = 2 * pi / lambda;

% 1. Full 360-degree range
theta_plot = -180:0.1:180; 
theta_rad = deg2rad(theta_plot);
theta0_rad = deg2rad(theta0);

% 2. Phase shift needed to steer beam
delta_phi = k * d * sin(theta0_rad);

% 3. Raw Interference Pattern (Array Factor)
psi = k * d * sin(theta_rad) - delta_phi;
AF = abs(sin(N * psi / 2) ./ (N * sin(psi / 2)));
AF(isnan(AF)) = 1; 

% 4. REAL-WORLD ELEMENT FACTOR (The Baffle)
EF = cos(theta_rad); 
EF(EF < 0) = 0; 

% 5. Combine: Total Pattern = Interference * Physical Baffle
pattern = AF .* EF;
pattern = pattern / max(pattern);

% === DETECT GRATING LOBES (Both m = -1 and m = +1) ===
lambda_over_d = lambda / d;

% m = -1 (grating lobe on opposite side)
sin_gl_minus = sind(theta0) - lambda_over_d;
if abs(sin_gl_minus) <= 1
    theta_gl_minus = asind(sin_gl_minus);
    amp_gl_minus = interp1(theta_plot, pattern, theta_gl_minus);
    visible_minus = true;
else
    theta_gl_minus = NaN;
    visible_minus = false;
end

% m = +1 (grating lobe on same side)
sin_gl_plus = sind(theta0) + lambda_over_d;
if abs(sin_gl_plus) <= 1
    theta_gl_plus = asind(sin_gl_plus);
    amp_gl_plus = interp1(theta_plot, pattern, theta_gl_plus);
    visible_plus = true;
else
    theta_gl_plus = NaN;
    visible_plus = false;
end

% === DISPLAY RESULTS ===
fprintf('\n========================================\n');
fprintf('BEAM STEERING RESULTS (Steering to %g°)\n', theta0);
fprintf('========================================\n');
fprintf('λ/d ratio: %.4f\n', lambda_over_d);
fprintf('d/λ ratio: %.2f\n', d/lambda);
fprintf('\nGrating Lobe Detection:\n');
if visible_minus
    fprintf('  ✓ m = -1 grating lobe at: %.1f°\n', theta_gl_minus);
else
    fprintf('  ✗ No visible grating lobe for m = -1\n');
end
if visible_plus
    fprintf('  ✓ m = +1 grating lobe at: %.1f°\n', theta_gl_plus);
else
    fprintf('  ✗ No visible grating lobe for m = +1 (sin = %.4f > 1)\n', sin_gl_plus);
end
fprintf('========================================\n\n');

% === FIGURE ===
figure('Color', 'w', 'Position', [100 100 1200 500]);

% --- RECTANGULAR PLOT ---
subplot(1,2,1);
plot(theta_plot, pattern, 'b-', 'LineWidth', 2); hold on;

% Plot MAIN LOBE (Green)
plot(theta0, 1, 'go', 'MarkerSize', 12, 'MarkerFaceColor', 'g', 'LineWidth', 1.5);

% Plot GRATING LOBE if visible (Red)
if visible_minus
    plot(theta_gl_minus, amp_gl_minus, 'rs', 'MarkerSize', 12, 'MarkerFaceColor', 'r', 'LineWidth', 1.5);
end
if visible_plus
    plot(theta_gl_plus, amp_gl_plus, 'rs', 'MarkerSize', 12, 'MarkerFaceColor', 'r', 'LineWidth', 1.5);
end

% Draw vertical dashed lines
xline(theta0, 'g--', 'LineWidth', 1, 'Alpha', 0.5);
if visible_minus
    xline(theta_gl_minus, 'r--', 'LineWidth', 1, 'Alpha', 0.5);
end
if visible_plus
    xline(theta_gl_plus, 'r--', 'LineWidth', 1, 'Alpha', 0.5);
end

% Add labels above peaks
text(theta0, 1.1, sprintf('MAIN LOBE\n%.1f°', theta0), ...
    'HorizontalAlignment', 'center', 'FontSize', 11, 'Color', [0 0.6 0], ...
    'FontWeight', 'bold');

if visible_minus
    text(theta_gl_minus, amp_gl_minus + 0.08, sprintf('GRATING LOBE\n%.1f°', theta_gl_minus), ...
        'HorizontalAlignment', 'center', 'FontSize', 11, 'Color', [0.8 0 0], ...
        'FontWeight', 'bold');
end

if visible_plus
    text(theta_gl_plus, amp_gl_plus + 0.08, sprintf('GRATING LOBE\n%.1f°', theta_gl_plus), ...
        'HorizontalAlignment', 'center', 'FontSize', 11, 'Color', [0.8 0 0], ...
        'FontWeight', 'bold');
end

% Formatting
grid on; box on;
xlim([-180 180]); ylim([0 1.2]);
xlabel('Angle (degrees)', 'FontSize', 12);
ylabel('Normalized Amplitude', 'FontSize', 12);
title('Beam Pattern - Rectangular View', 'FontSize', 14, 'FontWeight', 'bold');

% --- POLAR PLOT ---
subplot(1,2,2);
polarplot(theta_rad, pattern, 'b-', 'LineWidth', 2); hold on;

% Set orientation (North = 0°, East = 90°)
ax = gca;
ax.ThetaZeroLocation = 'top';
ax.ThetaDir = 'clockwise';
ax.FontSize = 10;

% Plot MAIN LOBE (Green)
polarplot(theta0_rad, 1, 'go', 'MarkerSize', 12, 'MarkerFaceColor', 'g');

% Plot GRATING LOBES if visible (Red)
if visible_minus
    polarplot(deg2rad(theta_gl_minus), amp_gl_minus, 'rs', 'MarkerSize', 12, 'MarkerFaceColor', 'r');
end
if visible_plus
    polarplot(deg2rad(theta_gl_plus), amp_gl_plus, 'rs', 'MarkerSize', 12, 'MarkerFaceColor', 'r');
end

% Add labels for lobes - PLACED OUTSIDE THE POLAR CIRCLE

% Main lobe label (outside at top)
[tx_main, ty_main] = pol2cart(theta0_rad, 1.25);
text(tx_main, ty_main, sprintf('MAIN LOBE\n%.1f°', theta0), ...
    'HorizontalAlignment', 'center', 'FontSize', 11, 'Color', [0 0.6 0], ...
    'FontWeight', 'bold');

% Grating lobe labels - positioned at the BOTTOM of the figure
% Get the position of the polar axes
axPos = ax.Position; % [left bottom width height]
figPos = get(gcf, 'Position');

% Create text boxes at the bottom of the figure (below the polar plot)
if visible_minus
    % Left side bottom (for negative angle)
    annotation('textbox', [0.62, 0.08, 0.12, 0.08], ...
        'String', sprintf('GRATING LOBE\n%.1f°', theta_gl_minus), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, ...
        'Color', [0.8 0 0], 'FontWeight', 'bold', ...
        'LineStyle', 'none', 'BackgroundColor', 'none');
end

if visible_plus
    % Right side bottom (for positive angle)
    annotation('textbox', [0.78, 0.08, 0.12, 0.08], ...
        'String', sprintf('GRATING LOBE\n%.1f°', theta_gl_plus), ...
        'HorizontalAlignment', 'center', 'FontSize', 10, ...
        'Color', [0.8 0 0], 'FontWeight', 'bold', ...
        'LineStyle', 'none', 'BackgroundColor', 'none');
end

% If both are visible, also show a connecting note
if visible_minus && visible_plus
    annotation('textbox', [0.70, 0.02, 0.08, 0.05], ...
        'String', 'Both grating lobes visible (symmetrical)', ...
        'HorizontalAlignment', 'center', 'FontSize', 8, ...
        'Color', [0.5 0.5 0.5], 'FontStyle', 'italic', ...
        'LineStyle', 'none', 'BackgroundColor', 'none');
end

% Add compass rose
[tx_n, ty_n] = pol2cart(0, 1.4);
text(tx_n, ty_n, 'N', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
[tx_e, ty_e] = pol2cart(pi/2, 1.4);
text(tx_e, ty_e, 'E', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
[tx_s, ty_s] = pol2cart(pi, 1.4);
text(tx_s, ty_s, 'S', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
[tx_w, ty_w] = pol2cart(-pi/2, 1.4);
text(tx_w, ty_w, 'W', 'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');

% Add reference circle
theta_circle = linspace(0, 2*pi, 100);
polarplot(theta_circle, ones(size(theta_circle)), 'k:', 'LineWidth', 0.5, 'Color', [0.7 0.7 0.7]);

title(sprintf('Beam Pattern - Polar View (0° = North, 90° = East)\nSteered to %g°', theta0), ...
    'FontSize', 14, 'FontWeight', 'bold');
