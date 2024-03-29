//
//  DragonBallTests.swift
//  DragonBallTests
//
//  Created by Rocio Martos on 21/3/24.
//

import XCTest
@testable import DragonBall
import Combine
import CombineCocoa
import UIKit
import KcLibraryswift

final class KcDragonBallProfTests: XCTestCase {
    
    func testKeyChainLibrary() throws {
        let kc = KeyChainKC()
        XCTAssertNotNil(kc)
        
        let save = kc.saveKC(key: "Test", value: "123")
        XCTAssertEqual(save, true)
        
        let value = kc.loadKC(key: "Test")
        if let valor = value{
            XCTAssertEqual(valor, "123")
        }
        
        XCTAssertNoThrow(kc.deleteKC(key: "Test"))
    }
    
    func testNetworkLogin() async throws {
        let obj1 = NetworkLogin()
        XCTAssertNotNil(obj1)
        let obj2 = NetworkLoginFake()
        XCTAssertNotNil(obj2)
        
        let tokenFake = await obj2.loginApp(user: "", password: "")
        XCTAssertNotEqual(tokenFake, "")
        
        let token = await obj1.loginApp(user: "lala", password: "papa")
        XCTAssertEqual(token, "")
    }
    
    func testLoginFake() async throws {
        let KC = KeyChainKC()
        XCTAssertNotNil(KC)
        
        let obj = LoginUseCaseFake()
        XCTAssertNotNil(obj)
        
        //validar el token
        let resp = await obj.validateToken()
        XCTAssertEqual(resp, true)
        
        //login
        let dloginDo = await obj.loginApp(user: "", password: "")
        XCTAssertEqual(dloginDo, true)
        
        var jwt = KC.loadKC(key: ConstantApp.CONST_TOKEN_ID_KEYCHAIN)
        XCTAssertNotEqual(jwt, "")
        
        
        //close session
        await obj.logout()
        jwt = KC.loadKC(key: ConstantApp.CONST_TOKEN_ID_KEYCHAIN)
        XCTAssertEqual(jwt, "")
    }
    
    
    func testLoginReal() async throws {
        let KC = KeyChainKC()
        XCTAssertNotNil(KC)
        
        KC.saveKC(key: ConstantApp.CONST_TOKEN_ID_KEYCHAIN, value: "")
        
        //Caso de uso con repo Fake
        let useCase = LoginUseCase(repo: DefaultLoginRespositoryFake())
        XCTAssertNotNil(useCase)
        
        //validar
        
        let resp = await useCase.validateToken()
        XCTAssertEqual(resp, false)
        
        //login
        let dloginDo = await useCase.loginApp(user: "", password: "")
        XCTAssertEqual(dloginDo, true)
        
        var jwt = KC.loadKC(key: ConstantApp.CONST_TOKEN_ID_KEYCHAIN)
        XCTAssertNotEqual(jwt, "")
        
        
        //close session
        await useCase.logout()
        jwt = KC.loadKC(key: ConstantApp.CONST_TOKEN_ID_KEYCHAIN)
        XCTAssertEqual(jwt, "")
        
    }
    
    
    
    
    // inicio de testing de heros....
    
    func testHeroViewModel() async throws {
        let vm = HerosViewModel(useCaseHeros: HeroUseCaseFake(), useCaseTransformations: TransformationsUseCaseFake())
        XCTAssertNotNil(vm)
        
        // XCTAssertEqual(vm.herosData.count, 2) //solo hay 2 heros
    }
    
    func testHerosUseCase() async throws {
        let usecase = HerosUseCase(repo: HerosRepositoryFake())
        XCTAssertNotNil(usecase)
        
        let data = await usecase.getHeros(filter: "")
        XCTAssertNotNil(data)
        XCTAssertEqual(data.count, 2)
    }
    
    func testHerosCombine() async throws {
        var suscriptor = Set<AnyCancellable>()
        
        let exp = self.expectation(description: "Heros get")
        
        let vm = HerosViewModel(useCaseHeros: HeroUseCaseFake(), useCaseTransformations: TransformationsUseCaseFake())
        XCTAssertNotNil(vm)
        
        //aqui la llamada a gerHeros...
        
        vm.$herosData
            .sink { completion in
                switch completion{
                case .finished:
                    print("finalizado")
                }
            } receiveValue: { data in
                if data.count == 2 {
                    exp.fulfill() // ha terminado la espera
                }
            }
            .store(in: &suscriptor)
        
        await self.waitForExpectations(timeout: 10)
        
        
        
    }
    
    func testHeros_Data() async throws {
        let network = NetworkHeros()
        XCTAssertNotNil(network)
        
        let repo = HerosRepository(Network: network)
        XCTAssertNotNil(repo)
        
        let repo2 = HerosRepositoryFake()
        XCTAssertNotNil(repo2)
        
        
        let data = await repo.getHeros(filter: "")
        XCTAssertNotNil(data)
        XCTAssertEqual(data.count, 0)
        
        let data2 = await repo2.getHeros(filter: "")
        XCTAssertNotNil(data2)
        XCTAssertEqual(data2.count, 2)
        
        
    }
    
    
    func testHerosDomain() async throws {
        let model = HerosModel(id: UUID(), favorite: true, description: "", photo: "", name: "goku")
        XCTAssertNotNil(model)
        
        XCTAssertEqual(model.name, "goku")
        XCTAssertEqual(model.favorite, true)
        XCTAssertEqual(model.getFullName(), "goku  $")
    }
    
    // MARK: - Hero Presentation Tests
    
    func testHerosPresentation() async throws {
        let viewModel = HerosViewModel(useCaseHeros: HeroUseCaseFake(), useCaseTransformations: TransformationsUseCaseFake())
        XCTAssertNotNil(viewModel)
        
        let view = await HerosTableViewController(appState: LoginViewModel(loginUseCase: LoginUseCaseFake()), viewModel: viewModel)
        XCTAssertNotNil(view)
    }
    
    
    // MARK: - Transformation UseCase Tests
    
    func testTransformUseCase() async throws {
        let useCase = TransformationsUseCase(repo: TransformationsRepository())
        XCTAssertNotNil(useCase)
        
        let transforms = try await useCase.getTransformations(forHeroWithID: UUID())
        XCTAssertNotNil(transforms)
        XCTAssertEqual(transforms.count, 0)
    }
    
    // MARK: - Transformation Combine Tests
    
    
    // MARK: - Transformation Data Tests
    
    func testTransformData() async throws {
        let network = NetworkTransformationsFake()
        XCTAssertNotNil(network)
        
        let repository = TransformationsRepository(network: network)
        XCTAssertNotNil(repository)
        
        let transformations = try await repository.getTransformations(forHeroWithID: UUID())
        XCTAssertNotNil(transformations)
        XCTAssertEqual(transformations.count, 1)
    }
    
    // MARK: - Transformation Domain Tests
    
    func testTransformDomain() async throws {
        let transformation = Transformation(id: UUID(), name: "Kaioken", description: "A technique used by Goku", photo: "")
        XCTAssertNotNil(transformation)
        
        XCTAssertEqual(transformation.name, "Kaioken")
        XCTAssertEqual(transformation.description, "A technique used by Goku")
    }
    func testUIElements() {
        let viewController = HerosTableViewController(appState: LoginViewModel(loginUseCase: LoginUseCaseFake()), viewModel: HerosViewModel(useCaseHeros: HeroUseCaseFake(), useCaseTransformations: TransformationsUseCaseFake()))
        XCTAssertNotNil(viewController)
        
        // Verifica que se hayan registrado las celdas correctamente
        let tableView = viewController.tableView
        XCTAssertNotNil(tableView)
        
        // Verifica que la vista tenga un título válido
        XCTAssertEqual(viewController.title, NSLocalizedString("Lista de Héroes", comment: "La lista de heroes"))
        
        // Verifica que el botón de cierre de sesión esté presente
        XCTAssertNotNil(viewController.navigationItem.rightBarButtonItem)
    }
}
