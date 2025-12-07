import React from "react";
import { ChevronLeft, Share, Heart, CheckCircle2, MapPin, MessageSquare, Star } from "lucide-react";
import { getTheme } from "../Common/Theme";
import { FreelancerProfile } from "../Common/types";

interface PublicProfileOverlayProps {
    selectedUserProfile: FreelancerProfile;
    onClose: () => void;
}

export const PublicProfileOverlay: React.FC<PublicProfileOverlayProps> = ({ selectedUserProfile, onClose }) => {
    const isDarkMode = true;
    const theme = getTheme(isDarkMode);

    return (
        <div className="absolute inset-0 z-[70] flex flex-col transition-colors duration-500 overflow-hidden animate-slide-up" style={{ backgroundColor: theme.phoneBg }}>
            <div className="absolute inset-0 bg-noise opacity-[0.03] pointer-events-none mix-blend-overlay z-0" />
            
            {/* Header Image */}
            <div className="h-[120px] w-full bg-gradient-to-r from-[#146068] to-[#93ccce] relative z-0">
                <button onClick={onClose} className="absolute top-8 left-4 w-10 h-10 rounded-full bg-black/20 backdrop-blur-md flex items-center justify-center text-white active:scale-95 transition-transform">
                <ChevronLeft className="w-6 h-6" />
                </button>
            </div>

            <div className="flex-1 overflow-y-auto px-5 relative z-10 -mt-12 pb-24" style={{ scrollbarWidth: "thin", scrollbarColor: theme.scrollbarColor }}>
                {/* Hero Card */}
                <div className={`${theme.cardBg} backdrop-blur-xl border ${theme.cardBorder} rounded-[24px] p-5 shadow-xl mb-6`}>
                <div className="flex justify-between items-start mb-4">
                    <div className="w-[80px] h-[80px] rounded-[24px] bg-[#f3bb19] border-4 border-[#0c0c0c] flex items-center justify-center text-[28px] font-extrabold text-[#0c0c0c] -mt-10 shadow-lg relative">
                        {selectedUserProfile.initials}
                        {selectedUserProfile.online && <div className="absolute -bottom-1 -right-1 w-5 h-5 bg-[#93ccce] rounded-full border-2 border-[#0c0c0c]" />}
                    </div>
                    <div className="flex gap-2">
                        <button className="w-10 h-10 rounded-full bg-[#146068]/10 flex items-center justify-center text-[#146068] hover:bg-[#146068]/20 transition-colors">
                            <Share className="w-5 h-5" />
                        </button>
                        <button className="w-10 h-10 rounded-full bg-[#f49d9d]/10 flex items-center justify-center text-[#f49d9d] hover:bg-[#f49d9d]/20 transition-colors">
                            <Heart className="w-5 h-5" />
                        </button>
                    </div>
                </div>
                
                <div className="mb-4">
                    <h2 className="text-[22px] font-black leading-tight mb-1" style={{ color: theme.text }}>
                        {selectedUserProfile.name} 
                        {selectedUserProfile.verified && <span className="inline-block ml-1 align-middle"><CheckCircle2 className="w-5 h-5 text-[#93ccce]" fill="#93ccce" stroke="#0c0c0c" /></span>}
                    </h2>
                    <p className="text-[14px] font-medium" style={{ color: theme.textSecondary }}>{selectedUserProfile.title}</p>
                    <div className="flex items-center gap-1 text-[12px] mt-1" style={{ color: theme.textTertiary }}>
                        <MapPin className="w-3 h-3" /> {selectedUserProfile.location}
                    </div>
                </div>

                <div className="flex justify-between items-center p-3 rounded-[16px] bg-[#146068]/5 border border-[#146068]/10">
                    <div className="text-center flex-1 border-r border-gray-500/10">
                        <div className="text-[16px] font-black text-[#146068]">{selectedUserProfile.jobSuccess}</div>
                        <div className="text-[10px] font-bold uppercase opacity-60" style={{ color: theme.text }}>Job Success</div>
                    </div>
                    <div className="text-center flex-1 border-r border-gray-500/10">
                        <div className="text-[16px] font-black" style={{ color: theme.text }}>{selectedUserProfile.jobsCompleted}</div>
                        <div className="text-[10px] font-bold uppercase opacity-60" style={{ color: theme.text }}>Total Jobs</div>
                    </div>
                    <div className="text-center flex-1">
                        <div className="text-[16px] font-black" style={{ color: theme.text }}>{selectedUserProfile.hourlyRate}</div>
                        <div className="text-[10px] font-bold uppercase opacity-60" style={{ color: theme.text }}>Hourly</div>
                    </div>
                </div>
                </div>

                {/* About */}
                <div className="mb-6">
                <h3 className="text-[16px] font-bold mb-3" style={{ color: theme.text }}>About</h3>
                <p className="text-[13px] leading-relaxed" style={{ color: theme.textSecondary }}>{selectedUserProfile.bio}</p>
                </div>

                {/* Skills */}
                <div className="mb-6">
                <h3 className="text-[16px] font-bold mb-3" style={{ color: theme.text }}>Skills</h3>
                <div className="flex flex-wrap gap-2">
                    {selectedUserProfile.skills.map(skill => (
                        <span key={skill} className={`px-3 py-1.5 rounded-lg text-[11px] font-bold border ${theme.cardBorder} bg-white/5`} style={{ color: theme.text }}>
                            {skill}
                        </span>
                    ))}
                </div>
                </div>

                {/* Portfolio */}
                <div className="mb-6">
                <h3 className="text-[16px] font-bold mb-3 flex items-center justify-between" style={{ color: theme.text }}>
                    Portfolio <span className="text-[12px] font-normal opacity-60 text-[#146068]">View All</span>
                </h3>
                <div className="columns-2 gap-3 space-y-3">
                    {selectedUserProfile.portfolio.map(item => (
                        <div key={item.id} className="break-inside-avoid rounded-[16px] overflow-hidden relative group">
                            <div className="w-full h-auto aspect-[4/5] bg-gray-200" style={{ backgroundColor: item.image }}></div>
                            <div className="absolute inset-0 bg-gradient-to-t from-black/80 to-transparent opacity-100 flex flex-col justify-end p-3">
                            <span className="text-[12px] font-bold text-white">{item.title}</span>
                            <span className="text-[10px] text-white/70">{item.category}</span>
                            </div>
                        </div>
                    ))}
                </div>
                </div>

                {/* Reviews */}
                <div className="mb-6">
                <h3 className="text-[16px] font-bold mb-3 flex items-center justify-between" style={{ color: theme.text }}>
                    Reviews <span className="text-[12px] font-normal opacity-60">Recent</span>
                </h3>
                <div className="space-y-3">
                    {selectedUserProfile.reviews.map(review => (
                        <div key={review.id} className={`p-4 rounded-[16px] ${theme.cardBg} border ${theme.cardBorder}`}>
                            <div className="flex justify-between items-start mb-2">
                            <div className="flex items-center gap-2">
                                <div className="w-8 h-8 rounded-full bg-[#93ccce] flex items-center justify-center text-[10px] font-black text-black">
                                    {review.clientInitials}
                                </div>
                                <div>
                                    <div className="text-[12px] font-bold" style={{ color: theme.text }}>{review.clientName}</div>
                                    <div className="flex text-[10px] text-[#f3bb19]">
                                        {[...Array(5)].map((_, i) => (
                                        <Star key={i} className={`w-3 h-3 ${i < review.rating ? "fill-[#f3bb19]" : "text-gray-400"}`} />
                                        ))}
                                    </div>
                                </div>
                            </div>
                            <span className="text-[10px]" style={{ color: theme.textSecondary }}>{review.date}</span>
                            </div>
                            <p className="text-[12px] italic leading-relaxed" style={{ color: theme.textSecondary }}>"{review.comment}"</p>
                        </div>
                    ))}
                </div>
                </div>
            </div>

            {/* Sticky Footer Action */}
            <div className={`absolute bottom-6 left-6 right-6 h-[60px] ${theme.bottomNavBg} backdrop-blur-2xl border ${theme.bottomNavBorder} rounded-[20px] flex items-center justify-between px-2 z-20 shadow-2xl`}>
                <button className="flex-1 h-[46px] flex items-center justify-center gap-2 text-[14px] font-bold" style={{ color: theme.text }}>
                <MessageSquare className="w-5 h-5" /> Message
                </button>
                <div className="w-[1px] h-[20px] bg-gray-500/20"></div>
                <button className="flex-1 h-[46px] bg-[#146068] rounded-[16px] text-white font-bold text-[14px] shadow-lg hover:scale-[1.02] active:scale-95 transition-transform mx-1">
                Hire Now
                </button>
            </div>
        </div>
    );
};