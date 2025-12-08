import React from 'react';
import { AuthView } from '../Common/types';

interface AuthScreenProps {
  authScreen: AuthView;
  setAuthScreen: (view: AuthView) => void;
  setIsLoggedIn: (val: boolean) => void;
  theme: any;
}

export default function AuthScreen({ authScreen, setAuthScreen, setIsLoggedIn, theme }: AuthScreenProps) {
  return (
    <div className={`flex-1 flex flex-col items-center justify-center px-8 py-12 bg-gradient-to-b ${theme.authGradient} transition-all duration-500 animate-fade-in relative z-10`}>
      <div className="w-full mb-8">
        <div className="w-20 h-20 bg-[#146068] rounded-[20px] mx-auto mb-6 flex items-center justify-center shadow-2xl animate-spring">
          <span className="text-[36px] font-extrabold text-[#f4f3f1]">S</span>
        </div>
        <h1 className="text-[32px] font-extrabold text-center mb-2 tracking-tight leading-none transition-colors duration-500" style={{ color: theme.authText }}>
          {authScreen === 'login' ? 'Welcome Back' : 'Create Account'}
        </h1>
        <p className="text-[14px] text-center transition-colors duration-500" style={{ color: theme.authTextSecondary }}>
          {authScreen === 'login' ? 'Sign in to continue to SLine' : 'Join SLine today'}
        </p>
      </div>

      <div className="w-full space-y-4 mb-6">
        {authScreen === 'signup' && (
           <div>
              <label className="text-[13px] font-semibold mb-2 block transition-colors duration-500" style={{ color: theme.authText }}>Full Name</label>
              <input type="text" placeholder="John Doe" className={`w-full h-[52px] ${theme.authInputBg} backdrop-blur-lg border-[1.5px] ${theme.authInputBorder} rounded-[14px] px-4 text-[14px] outline-none ${theme.inputFocusBg} focus:border-[#146068] transition-all duration-300`} style={{ color: theme.authInputText, '--placeholder-color': theme.authTextSecondary } as React.CSSProperties} />
           </div>
        )}
        <div>
          <label className="text-[13px] font-semibold mb-2 block transition-colors duration-500" style={{ color: theme.authText }}>Email</label>
          <input type="email" placeholder="your@email.com" className={`w-full h-[52px] ${theme.authInputBg} backdrop-blur-lg border-[1.5px] ${theme.authInputBorder} rounded-[14px] px-4 text-[14px] outline-none ${theme.inputFocusBg} focus:border-[#146068] transition-all duration-300`} style={{ color: theme.authInputText, '--placeholder-color': theme.authTextSecondary } as React.CSSProperties} />
        </div>
        <div>
          <label className="text-[13px] font-semibold mb-2 block transition-colors duration-500" style={{ color: theme.authText }}>Password</label>
          <input type="password" placeholder={authScreen === 'login' ? "Enter your password" : "Create a password"} className={`w-full h-[52px] ${theme.authInputBg} backdrop-blur-lg border-[1.5px] ${theme.authInputBorder} rounded-[14px] px-4 text-[14px] outline-none ${theme.inputFocusBg} focus:border-[#146068] transition-all duration-300`} style={{ color: theme.authInputText, '--placeholder-color': theme.authTextSecondary } as React.CSSProperties} />
        </div>
        {authScreen === 'login' && (
           <button className="text-[13px] font-semibold text-[#146068] hover:text-[#93ccce] transition-colors text-right w-full">Forgot Password?</button>
        )}
      </div>

      <button onClick={() => setIsLoggedIn(true)} className="w-full h-[54px] bg-[#146068] rounded-[14px] text-[15px] font-bold text-[#f4f3f1] hover:bg-[#146068]/90 transition-all duration-300 hover:scale-[1.02] active:scale-95 shadow-xl mb-4">
        {authScreen === 'login' ? 'Sign In' : 'Create Account'}
      </button>

      <div className="flex items-center gap-2 w-full mb-4">
        <div className={`flex-1 h-[1px] ${theme.dividerBg} transition-colors duration-500`}></div>
        <span className="text-[12px] font-semibold transition-colors duration-500" style={{ color: theme.authTextSecondary }}>OR</span>
        <div className={`flex-1 h-[1px] ${theme.dividerBg} transition-colors duration-500`}></div>
      </div>

      <div className="flex gap-3 w-full mb-6">
        <button className={`flex-1 h-[50px] ${theme.authInputBg} backdrop-blur-lg border ${theme.authInputBorder} rounded-[14px] flex items-center justify-center hover:bg-[#f4f3f1]/15 transition-all active:scale-95`}><span className="text-[20px]">🔍</span></button>
        <button className={`flex-1 h-[50px] ${theme.authInputBg} backdrop-blur-lg border ${theme.authInputBorder} rounded-[14px] flex items-center justify-center hover:bg-[#f4f3f1]/15 transition-all active:scale-95`}><span className="text-[20px]">📘</span></button>
        <button className={`flex-1 h-[50px] ${theme.authInputBg} backdrop-blur-lg border ${theme.authInputBorder} rounded-[14px] flex items-center justify-center hover:bg-[#f4f3f1]/15 transition-all active:scale-95`}><span className="text-[20px]">🍎</span></button>
      </div>

      <p className="text-[13px] text-center transition-colors duration-500" style={{ color: theme.authTextSecondary }}>
        {authScreen === 'login' ? "Don't have an account? " : "Already have an account? "}
        <button onClick={() => setAuthScreen(authScreen === 'login' ? "signup" : "login")} className="text-[#146068] font-bold hover:text-[#93ccce] transition-colors">
          {authScreen === 'login' ? "Sign Up" : "Sign In"}
        </button>
      </p>
    </div>
  );
}