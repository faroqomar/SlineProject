import React, { useState } from "react";
import { getTheme } from "../Common/Theme";
import { AuthView } from "../Common/types";

export const AuthScreens = ({ onLogin }: { onLogin: () => void }) => {
  const [authScreen, setAuthScreen] = useState<AuthView>("login");
  // Assuming dark mode is passed or handled via context, but for now defaulting to true as in the mock
  const isDarkMode = true; 
  const theme = getTheme(isDarkMode);

  return (
    <div
    className={`flex-1 flex flex-col items-center justify-center px-8 py-12 bg-gradient-to-b ${theme.authGradient} transition-all duration-500 animate-fade-in relative z-10 h-full`}
  >
     {/* Login/Signup content */}
    {authScreen === "login" ? (
      // Login Screen
      <>
        <div className="w-full mb-8">
          <div className="w-20 h-20 bg-[#146068] rounded-[20px] mx-auto mb-6 flex items-center justify-center shadow-2xl animate-spring">
            <span className="text-[36px] font-extrabold text-[#f4f3f1]">
              S
            </span>
          </div>
          <h1
            className="text-[32px] font-extrabold text-center mb-2 tracking-tight leading-none transition-colors duration-500"
            style={{ color: theme.authText }}
          >
            Welcome Back
          </h1>
          <p
            className="text-[14px] text-center transition-colors duration-500"
            style={{ color: theme.authTextSecondary }}
          >
            Sign in to continue to SLine
          </p>
        </div>

        <div className="w-full space-y-4 mb-6">
          <div>
            <label
              className="text-[13px] font-semibold mb-2 block transition-colors duration-500"
              style={{ color: theme.authText }}
            >
              Email
            </label>
            <input
              type="email"
              placeholder="your @email.com"
              className={`w-full h-[52px] ${theme.authInputBg} backdrop-blur-lg border-[1.5px] ${theme.authInputBorder} rounded-[14px] px-4 text-[14px] placeholder:text-[${theme.authTextSecondary}] outline-none ${theme.inputFocusBg} focus:border-[#146068] transition-all duration-300`}
              style={{ color: theme.authInputText }}
            />
          </div>
          <div>
            <label
              className="text-[13px] font-semibold mb-2 block transition-colors duration-500"
              style={{ color: theme.authText }}
            >
              Password
            </label>
            <input
              type="password"
              placeholder="Enter your password"
              className={`w-full h-[52px] ${theme.authInputBg} backdrop-blur-lg border-[1.5px] ${theme.authInputBorder} rounded-[14px] px-4 text-[14px] placeholder:text-[${theme.authTextSecondary}] outline-none ${theme.inputFocusBg} focus:border-[#146068] transition-all duration-300`}
              style={{ color: theme.authInputText }}
            />
          </div>
          <button className="text-[13px] font-semibold text-[#146068] hover:text-[#93ccce] transition-colors text-right w-full">
            Forgot Password?
          </button>
        </div>

        <button
          onClick={onLogin}
          className="w-full h-[54px] bg-[#146068] rounded-[14px] text-[15px] font-bold text-[#f4f3f1] hover:bg-[#146068]/90 transition-all duration-300 hover:scale-[1.02] active:scale-95 shadow-xl mb-4"
        >
          Sign In
        </button>

        <div className="flex items-center gap-2 w-full mb-4">
          <div
            className={`flex-1 h-[1px] ${theme.dividerBg} transition-colors duration-500`}
          ></div>
          <span
            className="text-[12px] font-semibold transition-colors duration-500"
            style={{ color: theme.authTextSecondary }}
          >
            OR
          </span>
          <div
            className={`flex-1 h-[1px] ${theme.dividerBg} transition-colors duration-500`}
          ></div>
        </div>

        <div className="flex gap-3 w-full mb-6">
          <button
            className={`flex-1 h-[50px] ${theme.authInputBg} backdrop-blur-lg border ${theme.authInputBorder} rounded-[14px] flex items-center justify-center hover:bg-[#f4f3f1]/15 transition-all active:scale-95`}
          >
            <span className="text-[20px]">🔍</span>
          </button>
          <button
            className={`flex-1 h-[50px] ${theme.authInputBg} backdrop-blur-lg border ${theme.authInputBorder} rounded-[14px] flex items-center justify-center hover:bg-[#f4f3f1]/15 transition-all active:scale-95`}
          >
            <span className="text-[20px]">📘</span>
          </button>
          <button
            className={`flex-1 h-[50px] ${theme.authInputBg} backdrop-blur-lg border ${theme.authInputBorder} rounded-[14px] flex items-center justify-center hover:bg-[#f4f3f1]/15 transition-all active:scale-95`}
          >
            <span className="text-[20px]">🍎</span>
          </button>
        </div>

        <p
          className="text-[13px] text-center transition-colors duration-500"
          style={{ color: theme.authTextSecondary }}
        >
          Don't have an account?{" "}
          <button
            onClick={() => setAuthScreen("signup")}
            className="text-[#146068] font-bold hover:text-[#93ccce] transition-colors"
          >
            Sign In
          </button>
        </p>
      </>
    ) : (
      // Signup Screen
      <>
         <div className="w-full mb-8">
          <div className="w-20 h-20 bg-[#146068] rounded-[20px] mx-auto mb-6 flex items-center justify-center shadow-2xl animate-spring">
            <span className="text-[36px] font-extrabold text-[#f4f3f1]">
              S
            </span>
          </div>
          <h1
            className="text-[32px] font-extrabold text-center mb-2 tracking-tight leading-none transition-colors duration-500"
            style={{ color: theme.authText }}
          >
            Create Account
          </h1>
          <p
            className="text-[14px] text-center transition-colors duration-500"
            style={{ color: theme.authTextSecondary }}
          >
            Join SLine today
          </p>
        </div>
         <div className="w-full space-y-4 mb-6">
          <div>
            <label
              className="text-[13px] font-semibold mb-2 block transition-colors duration-500"
              style={{ color: theme.authText }}
            >
              Full Name
            </label>
            <input
              type="text"
              placeholder="John Doe"
              className={`w-full h-[52px] ${theme.authInputBg} backdrop-blur-lg border-[1.5px] ${theme.authInputBorder} rounded-[14px] px-4 text-[14px] placeholder:text-[${theme.authTextSecondary}] outline-none ${theme.inputFocusBg} focus:border-[#146068] transition-all duration-300`}
              style={{ color: theme.authInputText }}
            />
          </div>
          <div>
            <label
              className="text-[13px] font-semibold mb-2 block transition-colors duration-500"
              style={{ color: theme.authText }}
            >
              Email
            </label>
            <input
              type="email"
              placeholder="your @email.com"
              className={`w-full h-[52px] ${theme.authInputBg} backdrop-blur-lg border-[1.5px] ${theme.authInputBorder} rounded-[14px] px-4 text-[14px] placeholder:text-[${theme.authTextSecondary}] outline-none ${theme.inputFocusBg} focus:border-[#146068] transition-all duration-300`}
              style={{ color: theme.authInputText }}
            />
          </div>
          <div>
            <label
              className="text-[13px] font-semibold mb-2 block transition-colors duration-500"
              style={{ color: theme.authText }}
            >
              Password
            </label>
            <input
              type="password"
              placeholder="Create a password"
              className={`w-full h-[52px] ${theme.authInputBg} backdrop-blur-lg border-[1.5px] ${theme.authInputBorder} rounded-[14px] px-4 text-[14px] placeholder:text-[${theme.authTextSecondary}] outline-none ${theme.inputFocusBg} focus:border-[#146068] transition-all duration-300`}
              style={{ color: theme.authInputText }}
            />
          </div>
        </div>

        <button
          onClick={onLogin}
          className="w-full h-[54px] bg-[#146068] rounded-[14px] text-[15px] font-bold text-[#f4f3f1] hover:bg-[#146068]/90 transition-all duration-300 hover:scale-[1.02] active:scale-95 shadow-xl mb-4"
        >
          Create Account
        </button>
        <div className="flex items-center gap-2 w-full mb-4">
          <div
            className={`flex-1 h-[1px] ${theme.dividerBg} transition-colors duration-500`}
          ></div>
          <span
            className="text-[12px] font-semibold transition-colors duration-500"
            style={{ color: theme.authTextSecondary }}
          >
            OR
          </span>
          <div
            className={`flex-1 h-[1px] ${theme.dividerBg} transition-colors duration-500`}
          ></div>
        </div>

        <div className="flex gap-3 w-full mb-6">
          <button
            className={`flex-1 h-[50px] ${theme.authInputBg} backdrop-blur-lg border ${theme.authInputBorder} rounded-[14px] flex items-center justify-center hover:bg-[#f4f3f1]/15 transition-all active:scale-95`}
          >
            <span className="text-[20px]">🔍</span>
          </button>
          <button
            className={`flex-1 h-[50px] ${theme.authInputBg} backdrop-blur-lg border ${theme.authInputBorder} rounded-[14px] flex items-center justify-center hover:bg-[#f4f3f1]/15 transition-all active:scale-95`}
          >
            <span className="text-[20px]">📘</span>
          </button>
          <button
            className={`flex-1 h-[50px] ${theme.authInputBg} backdrop-blur-lg border ${theme.authInputBorder} rounded-[14px] flex items-center justify-center hover:bg-[#f4f3f1]/15 transition-all active:scale-95`}
          >
            <span className="text-[20px]">🍎</span>
          </button>
        </div>

        <p
          className="text-[13px] text-center transition-colors duration-500"
          style={{ color: theme.authTextSecondary }}
        >
          Already have an account?{" "}
          <button
            onClick={() => setAuthScreen("login")}
            className="text-[#146068] font-bold hover:text-[#93ccce] transition-colors"
          >
            Sign In
          </button>
        </p>
      </>
    )}
  </div>
  );
};