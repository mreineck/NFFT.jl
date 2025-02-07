using CuNFFT
import CuNFFT.CuArray

m = 5
σ = 2.0

# test CuNFFT
if CuNFFT.CUDA.functional()
  @testset "CuNFFT in multiple dimensions" begin
    for (u,N) in enumerate([(256,), (32,32), (12,12,12)])
        eps = [1e-7, 1e-3, 1e-6, 1e-4]
        for (l,window) in enumerate([:kaiser_bessel, :gauss, :kaiser_bessel_rev, :spline])
            D = length(N)
            @info "Testing CuNFFT in $D dimensions using $window window"

            J = prod(N)
            k = rand(Float64,D,J) .- 0.5
            p = plan_nfft(Array, k, N; m, σ, window, precompute = NFFT.FULL,
                         fftflags = FFTW.ESTIMATE)
            p_d = plan_nfft(CuArray, k, N; m, σ, window, precompute = NFFT.FULL)
            pNDFT = NDFTPlan(k, N)

            fHat = rand(Float64,J) + rand(Float64,J)*im
            f = adjoint(pNDFT) * fHat
            fHat_d = CuArray(fHat)
            fApprox_d = adjoint(p_d) * fHat_d
            fApprox = Array(fApprox_d)
            e = norm(f[:] - fApprox[:]) / norm(f[:])
            @debug "error adjoint nfft "  e
            @test e < eps[l]

            gHat = pNDFT * f
            gHatApprox = Array( p_d * CuArray(f) )
            e = norm(gHat[:] - gHatApprox[:]) / norm(gHat[:])
            @debug "error nfft "  e
            @test e < eps[l]
        end
    end
  end
end

