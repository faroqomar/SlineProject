import React, { useEffect } from 'react';
import { Video, Mic, MicOff, PhoneOff, VideoOff } from 'lucide-react';
import { ActiveCall } from '../Common/types';

interface VideoCallModalProps {
  theme: any;
  activeCall: ActiveCall;
  setActiveCall: (call: ActiveCall | null) => void;
}

export default function VideoCallModal({ theme, activeCall, setActiveCall }: VideoCallModalProps) {
  useEffect(() => {
    // Simulate connection delay
    if (activeCall.status === 'calling') {
      const timer = setTimeout(() => {
        setActiveCall({ ...activeCall, status: 'connected' });
      }, 3000);
      return () => clearTimeout(timer);
    }
  }, [activeCall.status]);

  return (
    <div className="absolute inset-0 z-[100] bg-[#0c0c0c] flex flex-col items-center animate-slide-up">
      {/* Background with blur/noise */}
      <div className="absolute inset-0 bg-gradient-to-br from-[#146068]/30 to-[#000000] z-0" />
      <div className="absolute inset-0 bg-noise opacity-10 mix-blend-overlay z-0" />
      
      {/* Header */}
      <div className="relative z-10 w-full pt-12 pb-4 text-center">
        <h2 className="text-white/60 text-[14px] font-bold uppercase tracking-widest mb-2">
          {activeCall.status === 'calling' ? 'Calling...' : 'Connected'}
        </h2>
        <div className="flex items-center justify-center gap-2">
           <span className="w-2 h-2 bg-red-500 rounded-full animate-pulse" />
           <span className="text-white text-[12px] font-mono">04:23</span>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 w-full relative z-10 flex flex-col items-center justify-center">
         {/* User Avatar / Video Placeholder */}
         <div className="relative mb-12">
            {/* Ripples */}
            <div className="absolute inset-0 rounded-full bg-[#146068]/30 animate-ping opacity-20 scale-150" />
            <div className="absolute inset-0 rounded-full bg-[#146068]/20 animate-pulse delay-75 scale-125" />
            
            <div className="w-32 h-32 rounded-full border-4 border-white/10 relative overflow-hidden shadow-2xl z-20">
               {/* Placeholder for video stream */}
               <div className="absolute inset-0 bg-gray-800 flex items-center justify-center">
                  <span className="text-3xl">👤</span>
               </div>
               {/* If connected, show "video" (mock) */}
               {activeCall.status === 'connected' && (
                  <div className="absolute inset-0 bg-gradient-to-tr from-gray-900 to-gray-700 opacity-80" />
               )}
            </div>
            <h1 className="text-white text-[24px] font-bold mt-6 text-center">{activeCall.name}</h1>
         </div>
      </div>

      {/* Controls */}
      <div className="w-full relative z-10 px-8 pb-12">
         <div className="flex items-center justify-around p-4 rounded-[30px] bg-white/10 backdrop-blur-2xl border border-white/5 shadow-2xl">
            <button 
              onClick={() => setActiveCall({...activeCall, isMuted: !activeCall.isMuted})}
              className={`w-14 h-14 rounded-full flex items-center justify-center transition-all active:scale-90 ${activeCall.isMuted ? 'bg-white text-black' : 'bg-white/10 text-white'}`}
            >
               {activeCall.isMuted ? <MicOff className="w-6 h-6" /> : <Mic className="w-6 h-6" />}
            </button>
            
            <button 
              onClick={() => setActiveCall(null)}
              className="w-20 h-20 rounded-full bg-red-500 flex items-center justify-center text-white shadow-lg shadow-red-500/30 hover:scale-105 active:scale-95 transition-all"
            >
               <PhoneOff className="w-8 h-8 fill-current" />
            </button>

            <button 
              onClick={() => setActiveCall({...activeCall, isVideoOn: !activeCall.isVideoOn})}
              className={`w-14 h-14 rounded-full flex items-center justify-center transition-all active:scale-90 ${!activeCall.isVideoOn ? 'bg-white text-black' : 'bg-white/10 text-white'}`}
            >
               {!activeCall.isVideoOn ? <VideoOff className="w-6 h-6" /> : <Video className="w-6 h-6" />}
            </button>
         </div>
      </div>
    </div>
  );
}
